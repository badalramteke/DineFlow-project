import { useState, useEffect, useRef } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { db } from "../firebase";
import {
  collection,
  addDoc,
  onSnapshot,
  query,
  where,
  doc,
  getDoc,
} from "firebase/firestore";
import { GoogleGenerativeAI } from "@google/generative-ai";

// ⚠️ PASTE YOUR API KEY HERE
const GEMINI_API_KEY = import.meta.env.VITE_GEMINI_API_KEY;
const GEMINI_MODEL = "gemini-2.5-flash";

export default function CustomerMenu() {
  const { restroId, tableId } = useParams();
  const navigate = useNavigate();
  const [menu, setMenu] = useState([]);
  const [restaurantName, setRestaurantName] = useState("Loading...");

  // 1. LIVE BILL STATE (From Database)
  const [pendingOrders, setPendingOrders] = useState([]);
  const [orderedItemsCount, setOrderedItemsCount] = useState({}); // To show "Ordered: 2" on cards

  // 2. LOCAL CART STATE (Staging Area)
  const [cart, setCart] = useState(() => {
    const saved = localStorage.getItem("dineflow_cart");
    return saved ? JSON.parse(saved) : {};
  });

  // UI States
  const [activeCategory, setActiveCategory] = useState("All");
  const [foodTypeFilter, setFoodTypeFilter] = useState("all"); // "all", "veg", "non-veg"
  const [showCartModal, setShowCartModal] = useState(false);

  // AI States
  const [showChat, setShowChat] = useState(false);
  const [messages, setMessages] = useState([
    { role: "ai", text: "Hi! I'm your AI Foodie Guide. 🤖 Ask me anything!" },
  ]);
  const [input, setInput] = useState("");
  const [isTyping, setIsTyping] = useState(false);
  const chatEndRef = useRef(null);

  // Save Cart
  useEffect(() => {
    localStorage.setItem("dineflow_cart", JSON.stringify(cart));
  }, [cart]);

  // --- DATA FETCHING ---
  useEffect(() => {
    if (!restroId) return;

    // A. Get Restaurant Name
    const fetchRestro = async () => {
      const docRef = doc(db, "restaurants", restroId);
      const docSnap = await getDoc(docRef);
      setRestaurantName(
        docSnap.exists() ? docSnap.data().name : "Unknown Restaurant"
      );
    };
    fetchRestro();

    // B. Get Menu
    const qMenu = query(collection(db, "restaurants", restroId, "menus"));
    const unsubMenu = onSnapshot(qMenu, (snapshot) => {
      setMenu(snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() })));
    });

    // C. Get PENDING ORDERS (Live Bill)
    const qOrders = query(
      collection(db, "restaurants", restroId, "orders"),
      where("tableId", "==", tableId),
      where("paymentStatus", "==", "Pending")
    );
    const unsubOrders = onSnapshot(qOrders, (snapshot) => {
      const orders = snapshot.docs.map((doc) => doc.data());
      setPendingOrders(orders);

      // Calculate counts of already ordered items
      const counts = {};
      orders.forEach((order) => {
        order.items.forEach((item) => {
          counts[item.name] = (counts[item.name] || 0) + item.qty;
        });
      });
      setOrderedItemsCount(counts);
    });

    return () => {
      unsubMenu();
      unsubOrders();
    };
  }, [restroId, tableId]);

  // --- CART LOGIC ---
  const addToCart = (item) => {
    setCart((prev) => ({
      ...prev,
      [item.id]: {
        ...item,
        qty: (prev[item.id]?.qty || 0) + 1,
      },
    }));
  };

  const removeFromCart = (itemId) => {
    setCart((prev) => {
      const newCart = { ...prev };
      if (newCart[itemId].qty > 1) {
        newCart[itemId].qty -= 1;
      } else {
        delete newCart[itemId];
      }
      return newCart;
    });
  };

  const cartTotal = Object.values(cart).reduce(
    (sum, item) => sum + item.price * item.qty,
    0
  );
  const cartItemCount = Object.values(cart).reduce(
    (sum, item) => sum + item.qty,
    0
  );

  // --- PLACE ORDER ---
  const placeOrder = async () => {
    if (cartItemCount === 0) return;

    const orderData = {
      restaurantId: restroId,
      tableId: tableId,
      tableNumber: tableId,
      items: Object.values(cart).map((i) => ({
        name: i.name,
        price: i.price,
        qty: i.qty,
        variant: i.variant || "",
        customization: "",
      })),
      grandTotal: cartTotal,
      subTotal: cartTotal,
      taxAmount: 0,
      orderStatus: "pending",
      paymentStatus: "Pending",
      createdAt: new Date(),
      orderType: "Dine-in",
    };

    try {
      await addDoc(
        collection(db, "restaurants", restroId, "orders"),
        orderData
      );
      setCart({});
      localStorage.removeItem("dineflow_cart");
      setShowCartModal(false);
      alert("Order Placed Successfully! 👨‍🍳");
    } catch (error) {
      console.error("Error placing order:", error);
      alert("Failed to place order. Please try again.");
    }
  };

  // --- AI CHAT LOGIC ---
  const sendMessage = async () => {
    if (!input.trim()) return;

    const userMsg = { role: "user", text: input };
    setMessages((prev) => [...prev, userMsg]);
    setInput("");
    setIsTyping(true);

    try {
      const genAI = new GoogleGenerativeAI(GEMINI_API_KEY);
      const model = genAI.getGenerativeModel({ model: GEMINI_MODEL });

      const menuContext = menu
        .map((i) => `[ID: ${i.id}] ${i.name} (₹${i.price}) - ${i.description}`)
        .join("\n");

      const prompt = `
        You are a friendly waiter at ${restaurantName}.
        Here is the menu:
        ${menuContext}

        User asked: "${userMsg.text}"

        Strictly return a JSON object with this format (no markdown, just raw JSON):
        {
          "text": "Your friendly response here",
          "recommendedItemIds": ["id1", "id2"]
        }
        Only include ids if you are specifically recommending items from the menu based on the user's request.
      `;

      const result = await model.generateContent(prompt);
      const responseText = await result.response.text();

      // Clean up potential markdown code blocks
      const cleanJson = responseText.replace(/```json|```/g, "").trim();

      let aiMsg;
      try {
        const parsed = JSON.parse(cleanJson);
        aiMsg = {
          role: "ai",
          text: parsed.text,
          recommendations: parsed.recommendedItemIds || [],
        };
      } catch (e) {
        // Fallback
        aiMsg = { role: "ai", text: responseText };
      }

      setMessages((prev) => [...prev, aiMsg]);
    } catch (error) {
      console.error("AI Error:", error);
      let errorMsg = "Oops! My brain froze. 🧠 Try again?";
      if (error.message?.includes("400")) errorMsg += " (Bad Request)";
      if (error.message?.includes("401")) errorMsg += " (Invalid API Key)";
      if (error.message?.includes("403")) errorMsg += " (Access Denied)";
      if (error.message?.includes("404")) errorMsg += " (Model Not Found)";
      if (error.message?.includes("500")) errorMsg += " (Server Error)";

      setMessages((prev) => [
        ...prev,
        { role: "ai", text: errorMsg + `\nDetails: ${error.message}` },
      ]);
    } finally {
      setIsTyping(false);
    }
  };

  useEffect(() => {
    chatEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  // --- FILTERING ---
  const normalizeCategory = (cat) => {
    if (!cat) return "Other";
    const lower = cat.toLowerCase().trim();
    if (lower === "starter" || lower === "appetizers" || lower === "appetizer")
      return "Starters";
    return cat;
  };

  const categories = [
    "All",
    ...new Set(menu.map((item) => normalizeCategory(item.category))),
  ];
  const filteredMenu = menu.filter((item) => {
    const itemCategory = normalizeCategory(item.category);
    const matchesCategory =
      activeCategory === "All" || itemCategory === activeCategory;

    let matchesType = true;
    if (foodTypeFilter === "veg") matchesType = item.isVeg === true;
    if (foodTypeFilter === "non-veg") matchesType = item.isVeg === false;

    return matchesCategory && matchesType;
  });

  // Group items by category for the "All" view or just generally to show sections
  const groupedMenu = filteredMenu.reduce((acc, item) => {
    const cat = normalizeCategory(item.category);
    if (!acc[cat]) acc[cat] = [];
    acc[cat].push(item);
    return acc;
  }, {});
  const activeTrackingOrders = pendingOrders.filter((o) =>
    ["pending", "cooking", "ready"].includes(o.orderStatus?.toLowerCase())
  );

  return (
    <div className="min-h-screen bg-[#121212] font-sans pb-24 text-white">
      {/* 1. HEADER */}
      <div className="sticky top-0 z-40 bg-[#121212]/80 backdrop-blur-md border-b border-gray-800 shadow-lg">
        <div className="max-w-[1600px] mx-auto px-4 py-3 flex justify-between items-center">
          <div>
            <h1 className="text-xl font-black text-white tracking-tight">
              {restaurantName}
            </h1>
            <p className="text-xs text-gray-400 font-medium">
              Table {tableId} • Dine-in
            </p>
          </div>
          <div className="flex items-center gap-3">
            {/* View Bill / Active Orders Button */}
            {activeTrackingOrders.length > 0 && (
              <button
                onClick={() => navigate(`/checkout/${restroId}/${tableId}`)}
                className="flex items-center gap-1 px-3 py-1.5 rounded-full text-xs font-bold bg-orange-500/10 border border-orange-500/30 text-orange-500 animate-pulse"
              >
                <span>🧾 Orders</span>
              </button>
            )}

            {/* Food Type Filter Buttons */}
            <div className="flex items-center gap-2">
              <button
                onClick={() => setFoodTypeFilter("all")}
                className={`px-3 py-1 rounded-full text-xs font-bold border transition-all ${
                  foodTypeFilter === "all"
                    ? "bg-blue-600/10 border-blue-600 text-blue-600"
                    : "bg-[#1E1F23] border-gray-700 text-gray-400 hover:bg-gray-800"
                }`}
              >
                ALL
              </button>
              <button
                onClick={() => setFoodTypeFilter("veg")}
                className={`flex items-center gap-1 px-3 py-1 rounded-full text-xs font-bold border transition-all ${
                  foodTypeFilter === "veg"
                    ? "bg-[#00C853]/10 border-[#00C853] text-[#00C853]"
                    : "bg-[#1E1F23] border-gray-700 text-gray-400 hover:bg-gray-800"
                }`}
              >
                <span className="w-2 h-2 rounded-full bg-[#00C853]"></span>
                VEG
              </button>
              <button
                onClick={() => setFoodTypeFilter("non-veg")}
                className={`flex items-center gap-1 px-3 py-1 rounded-full text-xs font-bold border transition-all ${
                  foodTypeFilter === "non-veg"
                    ? "bg-red-600/10 border-red-600 text-red-600"
                    : "bg-[#1E1F23] border-gray-700 text-gray-400 hover:bg-gray-800"
                }`}
              >
                <span className="w-2 h-2 rounded-full bg-red-600"></span>
                NON-VEG
              </button>
            </div>
          </div>
        </div>

        {/* Categories */}
        <div className="max-w-[1600px] mx-auto px-4 pb-2 overflow-x-auto no-scrollbar flex gap-2">
          {categories.map((cat) => (
            <button
              key={cat}
              onClick={() => setActiveCategory(cat)}
              className={`whitespace-nowrap px-4 py-2 rounded-full text-sm font-bold transition-all ${
                activeCategory === cat
                  ? "bg-[#00C853] text-black shadow-lg shadow-[#00C853]/20"
                  : "bg-[#1E1F23] text-gray-400 border border-gray-800 hover:bg-gray-800"
              }`}
            >
              {cat}
            </button>
          ))}
        </div>
      </div>

      {/* 2. MENU SECTIONS */}
      <div className="max-w-[1600px] mx-auto p-4 sm:p-6 space-y-8">
        {Object.entries(groupedMenu).map(([category, items]) => (
          <div key={category}>
            {/* Section Header */}
            <h2 className="text-xl font-black text-white mb-4 px-1 border-l-4 border-[#00C853] pl-3">
              {category}
            </h2>

            {/* Items Grid */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4 sm:gap-6">
              {items.map((item) => (
                <div
                  key={item.id}
                  className="bg-[#1E1F23] rounded-3xl p-4 shadow-xl border border-gray-800 flex gap-4 relative overflow-hidden hover:border-gray-700 transition-colors"
                >
                  {/* Image */}
                  <div className="w-24 h-24 bg-[#121212] rounded-2xl flex-shrink-0 overflow-hidden border border-gray-800">
                    {item.imageUrl ? (
                      <img
                        src={item.imageUrl}
                        alt={item.name}
                        className="w-full h-full object-cover"
                      />
                    ) : (
                      <div className="w-full h-full flex items-center justify-center text-2xl">
                        🍽️
                      </div>
                    )}
                  </div>

                  {/* Content */}
                  <div className="flex-1 flex flex-col justify-between">
                    <div>
                      <div className="flex justify-between items-start">
                        <h3 className="font-bold text-white leading-tight text-lg">
                          {item.name}
                        </h3>
                        {item.isVeg ? (
                          <span className="text-[10px] border border-green-500 text-green-500 px-1 rounded">
                            ●
                          </span>
                        ) : (
                          <span className="text-[10px] border border-red-500 text-red-500 px-1 rounded">
                            ●
                          </span>
                        )}
                      </div>

                      {/* Category Tag - Optional now since we have headers, but keeping for clarity */}
                      <div className="flex items-center gap-2 mt-1">
                        <span className="text-[10px] font-bold px-2 py-0.5 rounded bg-[#121212] text-gray-500 uppercase tracking-wide border border-gray-800">
                          {item.category}
                        </span>
                      </div>

                      <p className="text-xs text-gray-400 mt-2 line-clamp-2 leading-relaxed">
                        {item.description}
                      </p>
                    </div>

                    <div className="flex justify-between items-end mt-3">
                      <span className="font-black text-xl text-white">
                        ₹{item.price}
                      </span>

                      {/* Add Button */}
                      {cart[item.id] ? (
                        <div className="flex items-center bg-[#00C853] rounded-xl shadow-lg shadow-[#00C853]/20">
                          <button
                            onClick={() => removeFromCart(item.id)}
                            className="px-3 py-1 text-black font-black text-lg hover:bg-black/10 rounded-l-xl"
                          >
                            -
                          </button>
                          <span className="text-black font-black text-sm px-1">
                            {cart[item.id].qty}
                          </span>
                          <button
                            onClick={() => addToCart(item)}
                            className="px-3 py-1 text-black font-black text-lg hover:bg-black/10 rounded-r-xl"
                          >
                            +
                          </button>
                        </div>
                      ) : (
                        <button
                          onClick={() => addToCart(item)}
                          className="bg-[#121212] border border-gray-700 text-[#00C853] px-4 py-2 rounded-xl font-bold text-sm shadow-sm uppercase tracking-wide active:scale-95 transition-transform hover:bg-gray-800"
                        >
                          ADD
                        </button>
                      )}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        ))}

        {/* Empty State */}
        {filteredMenu.length === 0 && (
          <div className="col-span-full text-center py-20 text-gray-600">
            <p className="text-6xl mb-4">🥗</p>
            <p className="text-xl font-bold">No items found.</p>
          </div>
        )}
      </div>

      {/* 3. FLOATING CART BAR */}
      {cartItemCount > 0 && (
        <div className="fixed bottom-6 left-0 right-0 px-4 z-50 max-w-md mx-auto">
          <button
            onClick={() => setShowCartModal(true)}
            className="w-full bg-[#00C853] text-black p-4 rounded-3xl shadow-2xl shadow-[#00C853]/30 flex justify-between items-center backdrop-blur-sm border border-[#00E676]"
          >
            <div className="flex flex-col items-start">
              <span className="text-xs font-bold opacity-80 uppercase tracking-wider">
                {cartItemCount} ITEMS
              </span>
              <span className="font-black text-xl">
                ₹{cartTotal.toFixed(2)}
              </span>
            </div>
            <div className="flex items-center gap-2 font-black text-lg">
              View Cart <span className="text-2xl">→</span>
            </div>
          </button>
        </div>
      )}

      {/* 3.1 FLOATING ACTIVE ORDERS BUTTON */}
      {cartItemCount === 0 && activeTrackingOrders.length > 0 && (
        <div className="fixed bottom-6 left-0 right-0 px-4 z-50 max-w-md mx-auto">
          <button
            onClick={() => navigate(`/checkout/${restroId}/${tableId}`)}
            className="w-full bg-orange-500 text-black p-4 rounded-3xl shadow-2xl shadow-orange-500/30 flex justify-between items-center backdrop-blur-sm border border-orange-400"
          >
            <div className="flex flex-col items-start">
              <span className="text-xs font-bold opacity-80 uppercase tracking-wider">
                {activeTrackingOrders.length} ACTIVE ORDERS
              </span>
              <span className="font-black text-xl">Track Status</span>
            </div>
            <div className="flex items-center gap-2 font-black text-lg">
              View Bill <span className="text-2xl">→</span>
            </div>
          </button>
        </div>
      )}

      {/* 4. AI CHAT BUTTON */}
      <button
        onClick={() => setShowChat(true)}
        className="fixed bottom-24 right-6 bg-blue-600 text-white p-4 rounded-full shadow-2xl shadow-blue-600/40 z-40 active:scale-90 transition-transform hover:scale-110 border-4 border-[#121212]"
      >
        <span className="text-2xl">🤖</span>
      </button>

      {/* 5. CART MODAL */}
      {showCartModal && (
        <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center bg-black/80 backdrop-blur-sm p-4">
          <div className="bg-[#1E1F23] w-full max-w-md rounded-3xl overflow-hidden shadow-2xl animate-slide-up border border-gray-800">
            <div className="p-6 bg-[#1E1F23] border-b border-gray-800 flex justify-between items-center">
              <h2 className="text-xl font-black text-white">Your Order</h2>
              <button
                onClick={() => setShowCartModal(false)}
                className="text-gray-400 hover:text-white bg-[#121212] w-8 h-8 rounded-full flex items-center justify-center"
              >
                ✕
              </button>
            </div>

            <div className="p-6 max-h-[50vh] overflow-y-auto space-y-4">
              {Object.values(cart).map((item) => (
                <div
                  key={item.id}
                  className="flex justify-between items-center"
                >
                  <div className="flex items-center gap-4">
                    <div className="w-2 h-2 rounded-full bg-[#00C853] shadow-[0_0_10px_#00C853]"></div>
                    <div>
                      <p className="font-bold text-white text-lg">
                        {item.name}
                      </p>
                      <p className="text-xs text-gray-400 font-mono">
                        ₹{item.price} x {item.qty}
                      </p>
                    </div>
                  </div>
                  <div className="flex items-center bg-[#121212] rounded-xl border border-gray-800">
                    <button
                      onClick={() => removeFromCart(item.id)}
                      className="px-3 py-2 text-gray-400 font-bold hover:text-white"
                    >
                      -
                    </button>
                    <span className="text-white font-bold text-sm px-2">
                      {item.qty}
                    </span>
                    <button
                      onClick={() => addToCart(item)}
                      className="px-3 py-2 text-[#00C853] font-bold hover:text-[#00E676]"
                    >
                      +
                    </button>
                  </div>
                </div>
              ))}
            </div>

            <div className="p-6 bg-[#1E1F23] border-t border-gray-800">
              <div className="flex justify-between items-center mb-6">
                <span className="text-gray-400 font-medium">Grand Total</span>
                <span className="text-3xl font-black text-white">
                  ₹{cartTotal.toFixed(2)}
                </span>
              </div>
              <button
                onClick={placeOrder}
                className="w-full bg-[#00C853] text-black py-4 rounded-2xl font-black text-lg shadow-lg shadow-[#00C853]/20 active:scale-95 transition-transform hover:bg-[#00E676]"
              >
                Place Order 👨‍🍳
              </button>
            </div>
          </div>
        </div>
      )}

      {/* 6. AI CHAT MODAL */}
      {showChat && (
        <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center bg-black/80 backdrop-blur-sm p-4">
          <div className="bg-[#1E1F23] w-full max-w-md h-[60vh] rounded-3xl overflow-hidden shadow-2xl flex flex-col border border-gray-800">
            <div className="p-4 bg-blue-600 text-white flex justify-between items-center">
              <div className="flex items-center gap-3">
                <span className="text-2xl bg-white/20 p-2 rounded-xl">🤖</span>
                <div>
                  <h3 className="font-bold text-lg">AI Foodie Guide</h3>
                  <p className="text-xs opacity-80 font-medium">
                    Ask for recommendations!
                  </p>
                </div>
              </div>
              <button
                onClick={() => setShowChat(false)}
                className="text-white/80 hover:text-white bg-black/20 w-8 h-8 rounded-full flex items-center justify-center"
              >
                ✕
              </button>
            </div>

            <div className="flex-1 p-4 overflow-y-auto space-y-3 bg-[#121212]">
              {messages.map((msg, idx) => (
                <div
                  key={idx}
                  className={`flex ${
                    msg.role === "user" ? "justify-end" : "justify-start"
                  }`}
                >
                  <div
                    className={`max-w-[85%] p-4 rounded-2xl text-sm leading-relaxed ${
                      msg.role === "user"
                        ? "bg-blue-600 text-white rounded-br-none shadow-lg shadow-blue-600/20"
                        : "bg-[#1E1F23] text-gray-200 shadow-sm border border-gray-800 rounded-bl-none"
                    }`}
                  >
                    {msg.text}

                    {/* AI Recommendations */}
                    {msg.recommendations && msg.recommendations.length > 0 && (
                      <div className="mt-3 space-y-2 pt-2 border-t border-gray-700/50">
                        <p className="text-xs font-bold text-gray-400 uppercase tracking-wider mb-2">
                          Recommended for you:
                        </p>
                        {msg.recommendations.map((recId) => {
                          const item = menu.find((m) => m.id === recId);
                          if (!item) return null;
                          return (
                            <div
                              key={recId}
                              className="bg-[#121212] p-3 rounded-xl border border-gray-800 flex justify-between items-center group hover:border-gray-600 transition-colors"
                            >
                              <div>
                                <p className="font-bold text-white text-sm">
                                  {item.name}
                                </p>
                                <p className="text-xs text-[#00C853] font-mono">
                                  ₹{item.price}
                                </p>
                              </div>
                              {cart[item.id] ? (
                                <div className="flex items-center bg-[#00C853] rounded-lg">
                                  <button
                                    onClick={() => removeFromCart(item.id)}
                                    className="px-2 py-1 text-black font-bold"
                                  >
                                    -
                                  </button>
                                  <span className="text-black text-xs font-bold px-1">
                                    {cart[item.id].qty}
                                  </span>
                                  <button
                                    onClick={() => addToCart(item)}
                                    className="px-2 py-1 text-black font-bold"
                                  >
                                    +
                                  </button>
                                </div>
                              ) : (
                                <button
                                  onClick={() => addToCart(item)}
                                  className="bg-[#00C853] text-black text-xs font-bold px-3 py-1.5 rounded-lg hover:bg-[#00E676] active:scale-95 transition-transform"
                                >
                                  ADD +
                                </button>
                              )}
                            </div>
                          );
                        })}
                      </div>
                    )}
                  </div>
                </div>
              ))}
              {isTyping && (
                <div className="flex justify-start">
                  <div className="bg-[#1E1F23] p-4 rounded-2xl rounded-bl-none shadow-sm border border-gray-800">
                    <div className="flex gap-1.5">
                      <span className="w-2 h-2 bg-gray-500 rounded-full animate-bounce"></span>
                      <span className="w-2 h-2 bg-gray-500 rounded-full animate-bounce delay-75"></span>
                      <span className="w-2 h-2 bg-gray-500 rounded-full animate-bounce delay-150"></span>
                    </div>
                  </div>
                </div>
              )}
              <div ref={chatEndRef} />
            </div>

            {/* Mini Cart Bar in Chat */}
            {cartItemCount > 0 && (
              <div className="px-4 py-3 bg-[#121212] border-t border-gray-800 flex justify-between items-center">
                <div className="flex items-center gap-2">
                  <div className="bg-[#00C853] w-2 h-2 rounded-full animate-pulse"></div>
                  <span className="text-white font-bold text-sm">
                    {cartItemCount} items
                  </span>
                  <span className="text-gray-500 text-xs">|</span>
                  <span className="text-[#00C853] font-black text-sm">
                    ₹{cartTotal.toFixed(2)}
                  </span>
                </div>
                <button
                  onClick={() => {
                    setShowChat(false);
                    setShowCartModal(true);
                  }}
                  className="bg-[#00C853] text-black text-xs font-bold px-4 py-2 rounded-lg hover:bg-[#00E676] shadow-lg shadow-[#00C853]/10"
                >
                  View Order →
                </button>
              </div>
            )}

            <div className="p-4 bg-[#1E1F23] border-t border-gray-800 flex gap-3">
              <input
                type="text"
                value={input}
                onChange={(e) => setInput(e.target.value)}
                onKeyDown={(e) => e.key === "Enter" && sendMessage()}
                placeholder="Ask about spicy food..."
                className="flex-1 bg-[#121212] border border-gray-800 rounded-xl px-4 py-3 text-white focus:ring-2 focus:ring-blue-500 focus:outline-none placeholder-gray-600"
              />
              <button
                onClick={sendMessage}
                className="bg-blue-600 text-white p-3 rounded-xl hover:bg-blue-700 transition-colors shadow-lg shadow-blue-600/20"
              >
                ➤
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
