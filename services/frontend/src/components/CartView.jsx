import React, { useEffect } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import { setCart, updateCartItem, removeCartItem } from '../features/cartSlice';

const CartView = () => {
  const dispatch = useDispatch();
  const cart = useSelector((state) => state.cart);

  useEffect(() => {
    const fetchCart = async () => {
      try {
        const response = await fetch('/api/cart');
        const data = await response.json();
        dispatch(setCart(data.items));
      } catch (error) {
        console.error('Error fetching cart:', error);
      }
    };

    fetchCart();
  }, [dispatch]);

  if (!cart || !cart.items || cart.items.length === 0) {
    return <div>Your cart is empty</div>;
  }

  const handleUpdateQuantity = async (itemId, quantity) => {
    try {
      await fetch(`/api/cart/items/${itemId}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ quantity }),
      });
      dispatch(updateCartItem({ id: itemId, quantity }));
    } catch (error) {
      console.error('Error updating quantity:', error);
    }
  };

  const handleDeleteItem = async (itemId) => {
    try {
      await fetch(`/api/cart/items/${itemId}`, {
        method: 'DELETE',
      });
      dispatch(removeCartItem(itemId));
    } catch (error) {
      console.error('Error deleting item:', error);
    }
  };

  return (
    <div>
      {cart.items.map((item) => (
        <div key={item.id} className="flex justify-between items-center border-b border-sre-orange py-4">
          <div>
            <h3 className="text-lg font-bold text-sre-cream">{item.name}</h3>
            <p className="text-sre-orange">${item.price}</p>
          </div>
          <div className="flex items-center">
            <input
              type="number"
              value={item.quantity}
              onChange={(e) => handleUpdateQuantity(item.id, e.target.value)}
              className="w-16 text-center border rounded bg-sre-dark-blue text-sre-cream border-sre-orange"
            />
            <button onClick={() => handleDeleteItem(item.id)} className="ml-4 text-red-500 hover:text-red-700">
              Remove
            </button>
          </div>
        </div>
      ))}
      <div className="flex justify-end items-center mt-4">
        <h3 className="text-xl font-bold mr-4 text-sre-cream">Total: ${cart.total}</h3>
        <a href="/checkout" className="bg-sre-orange hover:bg-orange-600 text-sre-cream font-bold py-2 px-4 rounded">
          Checkout
        </a>
      </div>
    </div>
  );
};

export default CartView;
