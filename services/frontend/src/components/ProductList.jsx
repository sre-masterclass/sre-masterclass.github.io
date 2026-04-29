import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';

const ProductList = () => {
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchProducts = async () => {
      try {
        const response = await fetch('/api/products');
        const data = await response.json();
        if (Array.isArray(data)) {
          setProducts(data);
        }
      } catch (error) {
        console.error('Error fetching products:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchProducts();
  }, []);

  if (loading) {
    return <div>Loading...</div>;
  }

  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-8">
      {Array.isArray(products) && products.map((product) => (
        <Link to={`/products/${product.id}`} key={product.id} className="border border-sre-orange rounded-lg overflow-hidden shadow-lg bg-sre-dark-blue hover:shadow-2xl hover:border-sre-cream transition-shadow duration-300">
          <img src={product.image_url} alt={product.name} className="w-full h-64 object-cover" />
          <div className="p-4">
            <h3 className="text-lg font-bold text-sre-cream">{product.name}</h3>
            <p className="text-sre-orange">${product.price}</p>
          </div>
        </Link>
      ))}
    </div>
  );
};

export default ProductList;
