const API = "http://localhost:3000";

async function fetchBalances() {
  const res = await fetch(`${API}/balances`);
  const data = await res.json();
  document.getElementById("playerBalance").innerText = data.playerBalance;
  document.getElementById("fundBalance").innerText = data.fundBalance;
}

document.getElementById("creditBtn").addEventListener("click", async () => {
  const amount = prompt("أدخل المبلغ لإضافته");
  if(!amount) return;
  await fetch(`${API}/credit`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ totalUsd: amount })
  });
  fetchBalances();
});

document.getElementById("withdrawBtn").addEventListener("click", async () => {
  const amount = document.getElementById("withdrawAmount").value;
  const to = document.getElementById("withdrawTo").value;
  if(!amount || !to) return alert("أدخل المبلغ والعنوان");
  await fetch(`${API}/withdraw`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ amount, to })
  });
  fetchBalances();
});

fetchBalances();
