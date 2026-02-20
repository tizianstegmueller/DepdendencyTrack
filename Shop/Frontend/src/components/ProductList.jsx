import ProductCard from './ProductCard'
import './ProductList.css'

function ProductList({ products }) {
  if (products.length === 0) {
    return (
      <div className="empty-state">
        <p>Keine Produkte verfügbar</p>
      </div>
    )
  }

  return (
    <div className="product-list">
      {products.map(product => (
        <ProductCard key={product.id} product={product} />
      ))}
    </div>
  )
}

export default ProductList
