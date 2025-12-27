import { useState } from "react";
import { BrowserRouter, Routes, Route, useNavigate } from "react-router-dom";
import CustomerMenu from "./pages/CustomerMenu";
import KitchenDashboard from "./pages/KitchenDashboard";
import Checkout from "./pages/Checkout";

function Home() {
  const [tableNum, setTableNum] = useState("1");
  const navigate = useNavigate();
  const RESTRO_ID = "arhb4deALpbavVQgcwnl";

  const handleOpenMenu = () => {
    if (!tableNum) return;
    navigate(`/menu/${RESTRO_ID}/${tableNum}`);
  };

  return (
    <div className="min-h-screen bg-gray-100 p-10 flex flex-col items-center justify-center font-sans">
      <div className="bg-white p-8 rounded-2xl shadow-xl max-w-md w-full text-center space-y-6">
        <h1 className="text-3xl font-black text-gray-800">🚀 DineFlow Dev</h1>

        {/* Kitchen Button */}
        <div className="space-y-2">
          <p className="text-sm text-gray-500 font-medium uppercase tracking-wider">
            Kitchen Display
          </p>
          <a
            href={`/kitchen?restaurantId=${RESTRO_ID}`}
            className="block w-full bg-blue-600 hover:bg-blue-700 text-white font-bold py-4 rounded-xl transition-all transform active:scale-95 shadow-lg shadow-blue-600/30"
          >
            👨‍🍳 Open Kitchen Dashboard
          </a>
          <p className="text-xs text-gray-400">ID: {RESTRO_ID}</p>
        </div>

        <div className="border-t border-gray-100 my-4"></div>

        {/* Customer Button */}
        <div className="space-y-3">
          <p className="text-sm text-gray-500 font-medium uppercase tracking-wider">
            Customer View
          </p>

          <div className="flex gap-2">
            <div className="relative flex-1">
              <span className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 text-sm font-bold">
                Table
              </span>
              <input
                type="number"
                value={tableNum}
                onChange={(e) => setTableNum(e.target.value)}
                className="w-full pl-14 pr-4 py-3 bg-gray-50 border-2 border-gray-200 rounded-xl focus:border-blue-500 focus:outline-none font-bold text-gray-700"
                placeholder="#"
              />
            </div>
          </div>

          <button
            onClick={handleOpenMenu}
            className="block w-full bg-white border-2 border-gray-200 hover:border-gray-300 text-gray-700 font-bold py-3 rounded-xl transition-all active:scale-95"
          >
            📱 Open Menu
          </button>
        </div>
      </div>
    </div>
  );
}

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/menu/:restroId/:tableId" element={<CustomerMenu />} />
        <Route path="/checkout/:restroId/:tableId" element={<Checkout />} />
        <Route path="/kitchen" element={<KitchenDashboard />} />
        <Route path="/" element={<Home />} />
      </Routes>
    </BrowserRouter>
  );
}

export default App;
