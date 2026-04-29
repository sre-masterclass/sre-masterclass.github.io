import React, { useState } from 'react';

const CheckoutForm = () => {
  const [formData, setFormData] = useState({
    firstName: '',
    lastName: '',
    address: '',
    city: '',
    state: '',
    zip: '',
  });

  const handleChange = (e) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      const paymentResponse = await fetch('/api/payment/charge', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(formData),
      });

      if (paymentResponse.ok) {
        // After successful payment, create the order
        const orderResponse = await fetch('/api/orders', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
        });

        if (orderResponse.ok) {
          const order = await orderResponse.json();
          window.location.href = `/dashboard?orderId=${order.id}`;
        } else {
          console.error('Order creation failed');
        }
      } else {
        console.error('Payment failed');
      }
    } catch (error) {
      console.error('Error processing payment:', error);
    }
  };

  return (
    <form className="w-full max-w-lg" onSubmit={handleSubmit}>
      <div className="flex flex-wrap -mx-3 mb-6">
        <div className="w-full md:w-1/2 px-3 mb-6 md:mb-0">
          <label className="block uppercase tracking-wide text-sre-cream text-xs font-bold mb-2" htmlFor="grid-first-name">
            First Name
          </label>
          <input className="appearance-none block w-full bg-sre-dark-blue text-sre-cream border border-sre-orange rounded py-3 px-4 mb-3 leading-tight focus:outline-none focus:bg-sre-cream focus:text-sre-dark-blue" id="grid-first-name" type="text" name="firstName" placeholder="Jane" onChange={handleChange} />
        </div>
        <div className="w-full md:w-1/2 px-3">
          <label className="block uppercase tracking-wide text-sre-cream text-xs font-bold mb-2" htmlFor="grid-last-name">
            Last Name
          </label>
          <input className="appearance-none block w-full bg-sre-dark-blue text-sre-cream border border-sre-orange rounded py-3 px-4 leading-tight focus:outline-none focus:bg-sre-cream focus:text-sre-dark-blue" id="grid-last-name" type="text" name="lastName" placeholder="Doe" onChange={handleChange} />
        </div>
      </div>
      <div className="flex flex-wrap -mx-3 mb-6">
        <div className="w-full px-3">
          <label className="block uppercase tracking-wide text-sre-cream text-xs font-bold mb-2" htmlFor="grid-password">
            Address
          </label>
          <input className="appearance-none block w-full bg-sre-dark-blue text-sre-cream border border-sre-orange rounded py-3 px-4 mb-3 leading-tight focus:outline-none focus:bg-sre-cream focus:text-sre-dark-blue" id="grid-password" type="text" name="address" placeholder="123 Main St" onChange={handleChange} />
        </div>
      </div>
      <div className="flex flex-wrap -mx-3 mb-2">
        <div className="w-full md:w-1/3 px-3 mb-6 md:mb-0">
          <label className="block uppercase tracking-wide text-sre-cream text-xs font-bold mb-2" htmlFor="grid-city">
            City
          </label>
          <input className="appearance-none block w-full bg-sre-dark-blue text-sre-cream border border-sre-orange rounded py-3 px-4 leading-tight focus:outline-none focus:bg-sre-cream focus:text-sre-dark-blue" id="grid-city" type="text" name="city" placeholder="Anytown" onChange={handleChange} />
        </div>
        <div className="w-full md:w-1/3 px-3 mb-6 md:mb-0">
          <label className="block uppercase tracking-wide text-sre-cream text-xs font-bold mb-2" htmlFor="grid-state">
            State
          </label>
          <div className="relative">
            <select className="block appearance-none w-full bg-sre-dark-blue border border-sre-orange text-sre-cream py-3 px-4 pr-8 rounded leading-tight focus:outline-none focus:bg-sre-cream focus:text-sre-dark-blue" id="grid-state" name="state" onChange={handleChange}>
              <option>New York</option>
              <option>California</option>
              <option>Texas</option>
            </select>
            <div className="pointer-events-none absolute inset-y-0 right-0 flex items-center px-2 text-sre-cream">
              <svg className="fill-current h-4 w-4" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20"><path d="M9.293 12.95l.707.707L15.657 8l-1.414-1.414L10 10.828 5.757 6.586 4.343 8z"/></svg>
            </div>
          </div>
        </div>
        <div className="w-full md:w-1/3 px-3 mb-6 md:mb-0">
          <label className="block uppercase tracking-wide text-sre-cream text-xs font-bold mb-2" htmlFor="grid-zip">
            Zip
          </label>
          <input className="appearance-none block w-full bg-sre-dark-blue text-sre-cream border border-sre-orange rounded py-3 px-4 leading-tight focus:outline-none focus:bg-sre-cream focus:text-sre-dark-blue" id="grid-zip" type="text" name="zip" placeholder="90210" onChange={handleChange} />
        </div>
      </div>
      <button className="bg-sre-orange hover:bg-orange-600 text-sre-cream font-bold py-2 px-4 rounded" type="submit">
        Pay
      </button>
    </form>
  );
};

export default CheckoutForm;
