import React, { useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';
import AddToCartButton from './AddToCartButton.jsx';

const ProductDetails = () => {
  const { productId } = useParams();
  const [product, setProduct] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchProduct = async () => {
      try {
        const response = await fetch(`/api/products/${productId}`);
        const data = await response.json();
        setProduct(data);
      } catch (error) {
        console.error('Error fetching product:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchProduct();
  }, [productId]);

  if (loading) {
    return <div>Loading...</div>;
  }

  if (!product) {
    return <div>Product not found</div>;
  }

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
      <div>
        <img src={product.image_url} alt={product.name} className="w-full rounded-lg shadow-lg" />
      </div>
      <div>
        <h2 className="text-3xl font-bold mb-4 text-sre-orange">{product.name}</h2>
        <p className="text-sre-cream mb-4">{product.description}</p>
        <p className="text-2xl font-bold text-sre-orange">${product.price}</p>
        <div className="mt-4">
          <AddToCartButton product={product} />
        </div>
      </div>
    </div>
  );
};

export default ProductDetails;
