import './ProductCard.css'

function ProductCard({ product }) {
  const formatPrice = (price) => {
    return new Intl.NumberFormat('de-DE', {
      style: 'currency',
      currency: 'EUR'
    }).format(price)
  }

  const getStockStatus = (stock) => {
    if (stock > 20) return { text: 'Auf Lager', className: 'in-stock' }
    if (stock > 0) return { text: 'Wenige verfügbar', className: 'low-stock' }
    return { text: 'Ausverkauft', className: 'out-of-stock' }
  }

  const stockStatus = getStockStatus(product.stock)

  return (
    <div className="product-card">
      <div className="product-image-container">
        <img 
          src={product.imageUrl} 
          alt={product.name}
          className="product-image"
          onError={(e) => {
            e.target.src = 'https://via.placeholder.com/400x300?text=Bild+nicht+verfügbar'
          }}
        />
        <span className={`stock-badge ${stockStatus.className}`}>
          {stockStatus.text}
        </span>
      </div>
      <div className="product-info">
        <h3 className="product-name">{product.name}</h3>
        <p className="product-description">{product.description}</p>
        <div className="product-footer">
          <span className="product-price">{formatPrice(product.price)}</span>
          <span className="product-stock">Lagerbestand: {product.stock}</span>
        </div>
      </div>
    </div>
  )
}

export default ProductCard
