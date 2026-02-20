import { useState, useEffect } from 'react'
import './App.css'
import ProductList from './components/ProductList'
import Header from './components/Header'

function App() {
  const [products, setProducts] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  useEffect(() => {
    fetchProducts()
  }, [])

  const fetchProducts = async () => {
    try {
      setLoading(true)
      const response = await fetch('http://localhost:5000/api/products')
      
      if (!response.ok) {
        throw new Error('Fehler beim Laden der Produkte')
      }
      
      const data = await response.json()
      setProducts(data)
      setError(null)
    } catch (err) {
      setError(err.message)
      console.error('Fehler:', err)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="App">
      <Header />
      <main className="main-content">
        {loading && <div className="loading">Lädt Produkte...</div>}
        {error && (
          <div className="error">
            <p>{error}</p>
            <button onClick={fetchProducts}>Erneut versuchen</button>
          </div>
        )}
        {!loading && !error && <ProductList products={products} />}
      </main>
    </div>
  )
}

export default App
