

require('dotenv').config();

const express = require('express');
const { Pool } = require('pg');

const app = express();


app.use(express.json());



app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Headers', 'Content-Type');
  next();
});

const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
});

// Endpoint de salud: sirve para verificar que el servidor está vivo

app.get('/health', (req, res) => {
  res.json({ status: 'ok', message: 'Backend Innovatech funcionando' });
});

// Endpoint principal: crea la tabla si no existe y retorna todos los productos
app.get('/api/productos', async (req, res) => {
  try {
    // Crea la tabla si no existe (útil para el primer arranque del contenedor)
    await pool.query(`
      CREATE TABLE IF NOT EXISTS productos (
        id SERIAL PRIMARY KEY,
        nombre VARCHAR(100) NOT NULL,
        precio NUMERIC(10,2) NOT NULL
      )
    `);

    const result = await pool.query('SELECT * FROM productos');
    res.json(result.rows);
  } catch (error) {
    console.error('Error en /api/productos:', error.message);
    res.status(500).json({ error: 'Error al conectar con la base de datos' });
  }
});

// Endpoint para crear un producto
app.post('/api/productos', async (req, res) => {
  const { nombre, precio } = req.body;
  try {
    const result = await pool.query(
      'INSERT INTO productos (nombre, precio) VALUES ($1, $2) RETURNING *',
      [nombre, precio]
    );
    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Error creando producto:', error.message);
    res.status(500).json({ error: 'Error al crear producto' });
  }
});



const PORT = process.env.PORT || 8080;

app.listen(PORT, () => {
  console.log(`Servidor corriendo en puerto ${PORT}`);
});
