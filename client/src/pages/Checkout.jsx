import { useState, useEffect } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { db } from "../firebase";
import {
  collection,
  query,
  where,
  getDocs,
  writeBatch,
  doc,
  updateDoc,
  getDoc,
  deleteDoc,
  onSnapshot,
} from "firebase/firestore";

export default function Checkout() {
  const { restroId, tableId } = useParams();
  const navigate = useNavigate();

  const [pendingOrders, setPendingOrders] = useState([]);
  const [loading, setLoading] = useState(true);
  const [isPaying, setIsPaying] = useState(false);
  const [paymentMethod, setPaymentMethod] = useState("upi");

  // 1. LISTEN TO LIVE BILL (Real-time updates)
  useEffect(() => {
    const q = query(
      collection(db, "restaurants", restroId, "orders"),
      where("tableId", "==", tableId),
      where("paymentStatus", "==", "Pending")
    );

    // Use onSnapshot so if Kitchen changes status to "Cooking",
    // the Cancel button disappears immediately for the user!
    const unsub = onSnapshot(q, (snapshot) => {
      const ordersData = snapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));
      // Sort by time
      ordersData.sort((a, b) => a.createdAt - b.createdAt);

      // FILTER 1: Exclude Served/Completed orders (Only show active kitchen orders)
      const activeOrders = ordersData.filter((order) =>
        ["pending", "cooking", "ready"].includes(
          order.orderStatus?.toLowerCase()
        )
      );

      // FILTER 2: Only show the LATEST active order
      const latestOrder =
        activeOrders.length > 0 ? [activeOrders[activeOrders.length - 1]] : [];

      setPendingOrders(latestOrder);
      setLoading(false);
    });

    return () => unsub();
  }, [restroId, tableId]);

  // --- CANCEL ITEM FUNCTION ---
  const handleCancelItem = async (orderId, itemIndex) => {
    if (!confirm("Are you sure you want to cancel this item?")) return;

    const orderRef = doc(db, "restaurants", restroId, "orders", orderId);
    const orderSnap = await getDoc(orderRef);

    if (!orderSnap.exists()) return;

    const orderData = orderSnap.data();

    // DOUBLE CHECK: Safety Check if Chef started cooking while you were deciding
    if (orderData.orderStatus !== "pending") {
      alert(
        "Sorry! The Chef just started cooking this order. Cannot cancel now."
      );
      return;
    }

    // Remove the specific item from the array
    const updatedItems = [...orderData.items];
    const removedItem = updatedItems.splice(itemIndex, 1)[0];

    // Recalculate price
    const newTotal = updatedItems.reduce((a, b) => a + b.price * b.qty, 0);

    if (updatedItems.length === 0) {
      // If no items left, delete the order document entirely
      await deleteDoc(orderRef);
    } else {
      // Update with remaining items
      await updateDoc(orderRef, {
        items: updatedItems,
        grandTotal: newTotal,
        subTotal: newTotal,
      });
    }
  };

  const calculateTotal = () => {
    return pendingOrders.reduce((total, order) => {
      const orderTotal =
        order.grandTotal ||
        order.totalAmount ||
        order.items.reduce((a, b) => a + b.price * b.qty, 0);
      return total + orderTotal;
    }, 0);
  };

  const handleFinalPayment = async () => {
    if (pendingOrders.length === 0) return alert("No pending bills to pay!");
    setIsPaying(true);
    await new Promise((resolve) => setTimeout(resolve, 2000));

    try {
      const batch = writeBatch(db);
      pendingOrders.forEach((order) => {
        const docRef = doc(db, "restaurants", restroId, "orders", order.id);
        batch.update(docRef, {
          paymentStatus: "Paid",
          paymentMethod: paymentMethod,
          paidAt: new Date(),
        });
      });
      await batch.commit();
      alert("Payment Successful! ✅");
      navigate(`/menu/${restroId}/${tableId}`);
    } catch (error) {
      alert("Payment Failed: " + error.message);
    }
    setIsPaying(false);
  };

  const total = calculateTotal();
  const tax = total * 0.05;
  const grandTotal = total + tax;

  if (loading)
    return (
      <div className="min-h-screen bg-[#121212] flex items-center justify-center text-white font-bold">
        Loading Bill...
      </div>
    );

  return (
    <div className="min-h-screen bg-[#121212] font-sans pb-10 text-white">
      {/* HEADER */}
      <div className="bg-[#121212]/80 backdrop-blur-md px-6 py-4 shadow-lg sticky top-0 z-10 flex items-center gap-4 border-b border-gray-800">
        <button
          onClick={() => navigate(-1)}
          className="w-10 h-10 rounded-full bg-[#1E1F23] flex items-center justify-center text-gray-400 hover:text-white hover:bg-gray-800 transition-colors border border-gray-800"
        >
          ←
        </button>
        <div>
          <h1 className="text-xl font-black text-white">Order Status</h1>
          <p className="text-xs text-gray-400 font-medium">
            Table {tableId} • Live Updates
          </p>
        </div>
      </div>

      {pendingOrders.length === 0 ? (
        <div className="flex flex-col items-center justify-center mt-20 px-6 text-center">
          <div className="w-20 h-20 bg-[#1E1F23] rounded-full flex items-center justify-center text-4xl mb-4 border border-gray-800">
            🍽️
          </div>
          <h2 className="text-xl font-bold text-white">No Active Orders</h2>
          <p className="text-gray-400 text-sm mt-2 mb-6">
            Looks like you haven't placed any orders yet.
          </p>
          <button
            onClick={() => navigate(-1)}
            className="bg-[#00C853] text-black px-8 py-3 rounded-xl font-bold shadow-lg shadow-[#00C853]/20 active:scale-95 transition-transform hover:bg-[#00E676]"
          >
            Browse Menu
          </button>
        </div>
      ) : (
        <div className="p-4 max-w-md mx-auto space-y-6">
          {/* ORDER CARDS */}
          {pendingOrders.map((order, index) => (
            <div
              key={order.id}
              className="bg-[#1E1F23] rounded-3xl shadow-xl border border-gray-800 overflow-hidden"
            >
              {/* Order Header */}
              <div className="bg-[#121212] px-6 py-4 border-b border-gray-800 flex justify-between items-center">
                <div>
                  <p className="text-xs font-bold text-gray-400 uppercase tracking-wider">
                    Order #{index + 1}
                  </p>
                  <p className="text-xs text-gray-500 font-medium mt-0.5">
                    {new Date(
                      order.createdAt?.seconds * 1000
                    ).toLocaleTimeString([], {
                      hour: "2-digit",
                      minute: "2-digit",
                    })}
                  </p>
                </div>
                <div
                  className={`px-3 py-1.5 rounded-full text-[10px] font-black uppercase tracking-wide border ${
                    order.orderStatus === "pending"
                      ? "bg-orange-500/10 text-orange-500 border-orange-500/30 animate-pulse"
                      : "bg-blue-500/10 text-blue-500 border-blue-500/30"
                  }`}
                >
                  {order.orderStatus === "pending"
                    ? "⏳ Waiting for Chef"
                    : "👨‍🍳 Cooking"}
                </div>
              </div>

              {/* Order Items */}
              <div className="p-6 space-y-6">
                {order.items.map((item, idx) => (
                  <div key={idx} className="flex gap-4">
                    {/* Item Icon Placeholder */}
                    <div className="w-12 h-12 bg-[#121212] rounded-xl flex items-center justify-center text-xl flex-shrink-0 border border-gray-800">
                      🥘
                    </div>

                    <div className="flex-1">
                      <div className="flex justify-between items-start mb-1">
                        <h3 className="font-bold text-white text-sm leading-tight">
                          {item.name}
                        </h3>
                        <span className="font-bold text-gray-200 text-sm">
                          ₹{item.price * item.qty}
                        </span>
                      </div>
                      <p className="text-xs text-gray-400 font-medium mb-3">
                        Qty: {item.qty} x ₹{item.price}
                      </p>

                      {/* Action Button */}
                      {order.orderStatus === "pending" ? (
                        <button
                          onClick={() => handleCancelItem(order.id, idx)}
                          className="text-red-400 text-[10px] font-bold border border-red-500/30 bg-red-500/10 px-3 py-1.5 rounded-lg hover:bg-red-500/20 transition-colors flex items-center gap-1"
                        >
                          <span>Cancel Item</span>
                        </button>
                      ) : (
                        <div className="inline-flex items-center gap-1.5 text-gray-400 text-[10px] font-bold bg-[#121212] px-3 py-1.5 rounded-lg border border-gray-800">
                          <span>👨‍🍳 Chef is cooking</span>
                        </div>
                      )}
                    </div>
                  </div>
                ))}
              </div>

              {/* Order Footer */}
              <div className="px-6 py-4 bg-[#121212] border-t border-gray-800 flex justify-between items-center">
                <span className="text-xs font-bold text-gray-500 uppercase">
                  Order Total
                </span>
                <span className="text-lg font-black text-white">
                  ₹
                  {order.items.reduce(
                    (acc, item) => acc + item.price * item.qty,
                    0
                  )}
                </span>
              </div>
            </div>
          ))}

          {/* BILL SUMMARY CARD */}
          <div className="bg-[#1E1F23] rounded-3xl shadow-xl border border-gray-800 p-6">
            <h3 className="text-sm font-black text-white mb-4 uppercase tracking-wide">
              Bill Summary
            </h3>
            <div className="space-y-3 text-sm">
              <div className="flex justify-between text-gray-400">
                <span>Subtotal</span>
                <span className="font-medium">₹{total}</span>
              </div>
              <div className="flex justify-between text-gray-400">
                <span>GST (5%)</span>
                <span className="font-medium">₹{tax.toFixed(2)}</span>
              </div>
              <div className="border-t border-dashed border-gray-700 my-3 pt-3 flex justify-between items-center">
                <span className="font-bold text-white">Grand Total</span>
                <span className="text-xl font-black text-[#00C853]">
                  ₹{grandTotal.toFixed(2)}
                </span>
              </div>
            </div>

            <div className="mt-6 p-4 bg-blue-500/10 rounded-2xl flex gap-3 items-start border border-blue-500/20">
              <span className="text-xl">💁‍♂️</span>
              <div>
                <p className="text-xs font-bold text-blue-400 mb-1">
                  Payment Information
                </p>
                <p className="text-[11px] text-blue-300 leading-relaxed font-medium">
                  Please pay at the counter or ask your server for the bill when
                  you're done dining.
                </p>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
