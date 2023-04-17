import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App";
import "./output.css";
import { WalletProvider } from "@suiet/wallet-kit";
import "@suiet/wallet-kit/style.css";

ReactDOM.createRoot(document.getElementById("root")).render(
  <WalletProvider>
    <React.StrictMode>
      <App />
    </React.StrictMode>
  </WalletProvider>
);
