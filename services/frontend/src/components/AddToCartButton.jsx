import React from 'react';
import { useDispatch } from 'react-redux';
import { addToCart } from '../features/cartSlice';

const AddToCartButton = ({ product }) => {
  const dispatch = useDispatch();

  const handleAddToCart = async () => {
    try {
      const response = await fetch('/api/cart/add', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ product_id: product.id, quantity: 1 }),
      });
      if (response.ok) {
        dispatch(addToCart(product));
      }
    } catch (error) {
      console.error('Error adding to cart:', error);
    }
  };

  return (
    <button
      onClick={handleAddToCart}
      className="bg-sre-orange hover:bg-orange-600 text-sre-cream font-bold py-2 px-4 rounded"
    >
      Add to Cart
    </button>
  );
};

export default AddToCartButton;
