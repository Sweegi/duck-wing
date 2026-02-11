const path = require('path')
const fs = require('fs')
const express = require('express')
const app = express()
app.use(express.json())

const configPath = path.join(__dirname, 'config.json')
const config = JSON.parse(fs.readFileSync(configPath, 'utf8'))

config.routes.forEach((route) => {
  const method = (route.method || 'get').toLowerCase()
  app[method](route.path, (req, res) => {
    const scenario = req.query.__scenario || req.get('X-Mock-Scenario') || 'success'
    const response = route.responses[scenario] || route.responses.success
    if (!response) return res.status(404).json({ message: 'Mock scenario not found' })
    res.status(response.status || 200).json(response.body || {})
  })
})

app.listen(config.port || 5176, () => {
  console.log(`Mock server at http://localhost:${config.port || 5176}`)
})
