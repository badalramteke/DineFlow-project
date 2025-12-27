import { useState, useEffect } from "react";
import { db } from "../firebase";
import {
  collection,
  onSnapshot,
  query,
  orderBy,
  updateDoc,
  doc,
} from "firebase/firestore";

export default function KitchenDashboard() {
  const [orders, setOrders] = useState([]);

  // Get Restaurant ID from URL (e.g., ?restaurantId=xyz)
  const queryParams = new URLSearchParams(window.location.search);
  const RESTAURANT_ID = queryParams.get("restaurantId");

  // 1. Listen to Orders in Real-Time
  useEffect(() => {
    if (!RESTAURANT_ID) return;

    // Listen to orders for this specific restaurant
    const ordersRef = collection(db, "restaurants", RESTAURANT_ID, "orders");
    const q = query(ordersRef, orderBy("createdAt", "asc"));

    const unsub = onSnapshot(q, (snapshot) => {
      const allOrders = snapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));

      // Client-side filtering: Only show active kitchen orders
      const activeOrders = allOrders.filter((o) =>
        ["cooking", "ready", "served"].includes(o.orderStatus?.toLowerCase())
      );
      setOrders(activeOrders);
    });
    return unsub;
  }, [RESTAURANT_ID]);

  // 2. Move Order to Next Stage
  const updateStatus = async (id, currentStatus) => {
    if (!RESTAURANT_ID) return;

    const status = currentStatus.toLowerCase();
    let nextStatus = "";

    if (status === "cooking") nextStatus = "ready";
    else if (status === "ready") nextStatus = "served";

    if (nextStatus) {
      await updateDoc(doc(db, "restaurants", RESTAURANT_ID, "orders", id), {
        orderStatus: nextStatus,
        updatedAt: new Date(),
      });
    }
  };

  // Helper for Timestamps
  const formatTime = (timestamp) => {
    if (!timestamp) return "";
    const date = timestamp.seconds
      ? new Date(timestamp.seconds * 1000)
      : new Date(timestamp);
    return date.toLocaleTimeString([], {
      hour: "2-digit",
      minute: "2-digit",
    });
  };

  if (!RESTAURANT_ID) {
    return (
      <div className="min-h-screen bg-[#121212] flex items-center justify-center text-white font-sans">
        <div className="text-center p-8 bg-[#1E1F23] rounded-3xl shadow-2xl border border-gray-800 max-w-md mx-4">
          <div className="text-6xl mb-6">👨‍🍳</div>
          <h1 className="text-3xl font-black mb-4 text-white">
            Kitchen Display
          </h1>
          <p className="text-gray-400 mb-6 leading-relaxed">
            Please add your restaurant ID to the URL to connect to the kitchen
            system.
          </p>
          <code className="block bg-[#121212] p-4 rounded-xl text-[#00C853] font-mono text-sm break-all border border-gray-800">
            /kitchen?restaurantId=YOUR_ID
          </code>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[#121212] font-sans text-white pb-20">
      {/* HEADER */}
      <div className="sticky top-0 z-50 bg-[#121212]/80 backdrop-blur-md border-b border-gray-800 shadow-lg">
        <div className="max-w-[1600px] mx-auto px-4 sm:px-6 py-4 flex flex-col sm:flex-row justify-between items-center gap-4">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 bg-[#00C853]/20 rounded-2xl flex items-center justify-center text-2xl border border-[#00C853]/30">
              🔥
            </div>
            <div>
              <h1 className="text-2xl font-black text-white tracking-tight">
                Kitchen Display
              </h1>
              <p className="text-gray-400 text-xs font-bold uppercase tracking-wider">
                Live Feed • {orders.length} Active Orders
              </p>
            </div>
          </div>

          <div className="flex items-center gap-3 bg-[#1E1F23] p-1.5 rounded-xl border border-gray-800">
            {/* Status Legend */}
            <div className="flex items-center gap-2 px-3 py-1.5 bg-[#121212] rounded-lg border border-gray-800">
              <span className="w-2.5 h-2.5 bg-orange-500 rounded-full animate-pulse"></span>
              <span className="text-xs font-bold text-gray-400">Cooking</span>
            </div>
            <div className="flex items-center gap-2 px-3 py-1.5 bg-[#121212] rounded-lg border border-gray-800">
              <span className="w-2.5 h-2.5 bg-[#00C853] rounded-full"></span>
              <span className="text-xs font-bold text-gray-400">Ready</span>
            </div>
            <div className="flex items-center gap-2 px-3 py-1.5 bg-[#121212] rounded-lg border border-gray-800">
              <span className="w-2.5 h-2.5 bg-blue-500 rounded-full"></span>
              <span className="text-xs font-bold text-gray-400">Served</span>
            </div>
          </div>
        </div>
      </div>

      {/* ORDERS GRID */}
      <div className="max-w-[1600px] mx-auto p-4 sm:p-6">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
          {orders.map((order) => (
            <div
              key={order.id}
              className={`relative bg-[#1E1F23] rounded-3xl overflow-hidden shadow-xl border-2 flex flex-col transition-all duration-300 hover:-translate-y-1 ${
                order.orderStatus === "cooking"
                  ? "border-orange-500/50 shadow-orange-500/10"
                  : order.orderStatus === "ready"
                  ? "border-[#00C853]/50 shadow-[#00C853]/10"
                  : "border-blue-500/30 opacity-75 grayscale-[0.3]"
              }`}
            >
              {/* Order Card Header */}
              <div
                className={`p-5 border-b flex justify-between items-start ${
                  order.orderStatus === "cooking"
                    ? "bg-orange-500/10 border-orange-500/20"
                    : order.orderStatus === "ready"
                    ? "bg-[#00C853]/10 border-[#00C853]/20"
                    : "bg-blue-500/10 border-blue-500/20"
                }`}
              >
                <div>
                  <div className="flex items-center gap-2 mb-1">
                    <span className="text-xs font-black text-gray-400 uppercase tracking-wider">
                      {formatTime(order.createdAt)}
                    </span>
                    <span className="text-[10px] bg-[#121212] px-2 py-0.5 rounded-md border border-gray-700 text-gray-400 font-mono">
                      #{order.orderId?.slice(-4) || "---"}
                    </span>
                  </div>
                  <h2 className="text-2xl font-black text-white">
                    {order.tableNumber === "Takeaway"
                      ? "🥡 Takeaway"
                      : `Table ${order.tableNumber}`}
                  </h2>
                  {order.orderType && (
                    <span className="text-xs font-bold text-gray-400 uppercase tracking-wide">
                      {order.orderType}
                    </span>
                  )}
                </div>
                <span
                  className={`px-3 py-1.5 rounded-xl text-[10px] font-black uppercase tracking-wide shadow-sm border ${
                    order.orderStatus === "cooking"
                      ? "bg-orange-500 text-black border-orange-400 animate-pulse"
                      : order.orderStatus === "ready"
                      ? "bg-[#00C853] text-black border-[#00E676]"
                      : "bg-blue-500 text-white border-blue-400"
                  }`}
                >
                  {order.orderStatus}
                </span>
              </div>

              {/* Kitchen Note */}
              {order.kitchenNote && (
                <div className="bg-red-500/10 p-3 px-5 border-b border-red-500/20 flex items-start gap-3">
                  <span className="text-lg">⚠️</span>
                  <p className="text-red-400 text-xs font-bold leading-relaxed pt-1">
                    {order.kitchenNote}
                  </p>
                </div>
              )}

              {/* Items List */}
              <div className="p-5 space-y-4 flex-1 overflow-y-auto max-h-[350px] bg-[#1E1F23]">
                {order.items?.map((item, idx) => (
                  <div
                    key={idx}
                    className="flex items-start gap-4 pb-4 border-b border-gray-800 last:border-0 last:pb-0"
                  >
                    <div className="w-8 h-8 bg-[#121212] rounded-lg flex items-center justify-center font-black text-gray-400 text-sm border border-gray-800">
                      {item.qty}
                    </div>
                    <div className="flex-1">
                      <div className="flex justify-between items-start">
                        <span className="font-bold text-gray-200 text-lg leading-tight">
                          {item.name}
                        </span>
                      </div>
                      {item.variant && (
                        <span className="text-xs font-bold text-gray-400 uppercase tracking-wide bg-[#121212] px-2 py-0.5 rounded mt-1 inline-block border border-gray-800">
                          {item.variant}
                        </span>
                      )}
                      {item.customization && (
                        <p className="text-orange-400 text-xs font-medium mt-1.5 bg-orange-500/10 p-2 rounded-lg border border-orange-500/20 italic">
                          "{item.customization}"
                        </p>
                      )}
                    </div>
                  </div>
                ))}
              </div>

              {/* Action Footer */}
              <div className="p-4 bg-[#121212]/50 border-t border-gray-800 mt-auto">
                {order.orderStatus === "served" ? (
                  <div className="w-full py-4 rounded-2xl font-bold text-sm bg-blue-500/10 border border-blue-500/30 text-blue-400 flex justify-center items-center gap-2 uppercase tracking-wide">
                    <span>Payment Pending 💳</span>
                  </div>
                ) : (
                  <button
                    onClick={() => updateStatus(order.id, order.orderStatus)}
                    className={`w-full py-4 rounded-2xl font-black text-sm uppercase tracking-wider transition-all active:scale-95 shadow-lg flex justify-center items-center gap-2 ${
                      order.orderStatus === "cooking"
                        ? "bg-orange-500 hover:bg-orange-600 text-black shadow-orange-500/20"
                        : "bg-[#00C853] hover:bg-[#00E676] text-black shadow-[#00C853]/20"
                    }`}
                  >
                    {order.orderStatus === "cooking" && (
                      <>
                        Mark Ready <span className="text-lg">✅</span>
                      </>
                    )}
                    {order.orderStatus === "ready" && (
                      <>
                        Mark Served <span className="text-lg">🍽️</span>
                      </>
                    )}
                  </button>
                )}
              </div>
            </div>
          ))}
        </div>

        {/* Empty State */}
        {orders.length === 0 && (
          <div className="flex flex-col items-center justify-center py-32 text-gray-600 animate-fade-in">
            <div className="w-32 h-32 bg-[#1E1F23] rounded-full flex items-center justify-center text-6xl mb-6 border border-gray-800">
              👨‍🍳
            </div>
            <h2 className="text-2xl font-black text-white mb-2">
              Kitchen is Clear!
            </h2>
            <p className="font-medium text-gray-500">
              Waiting for new orders to arrive...
            </p>
          </div>
        )}
      </div>
    </div>
  );
}
