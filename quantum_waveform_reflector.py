import requests
import time
import numpy as np
import pandas as pd
from birdeyepy import BirdEye


def get_creation_time(address):
    url = "https://api.mainnet-beta.solana.com"
    signatures = []
    before = None
    while True:
        params = [address, {"limit": 1000}]
        if before:
            params[1]["before"] = before
        payload = {
            "jsonrpc": "2.0",
            "id": 1,
            "method": "getSignaturesForAddress",
            "params": params
        }
        resp = requests.post(url, json=payload)
        data = resp.json().get('result', [])
        if not data:
            break
        signatures.extend(data)
        before = data[-1]['signature']
    if not signatures:
        raise ValueError("No transactions found for the address")
    oldest_sig = signatures[-1]['signature']
    payload = {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "getTransaction",
        "params": [oldest_sig, {"maxSupportedTransactionVersion": 0, "encoding": "json"}]
    }
    resp = requests.post(url, json=payload)
    tx = resp.json().get('result')
    if not tx:
        raise ValueError("Transaction details not found")
    block_time = tx['blockTime']
    return block_time


def compute_memory_strength(pct_changes):
    if pct_changes.std() == 0:
        return 0
    return np.mean(np.abs(pct_changes)) / np.std(pct_changes)


def classify_score(score):
    if score > 0.8:
        return "Insider Echo Detected"
    elif score > 0.5:
        return "Likely Pump, Reflector Sync"
    elif score > 0.2:
        return "Weak Signal, Probationary Phase"
    else:
        return "Decay Signature Detected"


def main(api_key, new_address):
    client = BirdEye(api_key=api_key)
    creation_new = get_creation_time(new_address)
    time_to = int(time.time())

    # Get jumper waveform
    history_new = client.defi.history_price(
        address=new_address,
        type_="1h",
        time_from=creation_new,
        time_to=time_to
    )
    items_new = history_new.get('data', {}).get('items', [])
    if not items_new:
        print("No historical price data for the new coin.")
        return

    df_new = pd.DataFrame(items_new)
    df_new['time'] = pd.to_datetime(df_new['unixTime'], unit='s')
    df_new.set_index('time', inplace=True)
    price_new = df_new['value']
    normalized_new = price_new / price_new.iloc[0]
    len_n = len(normalized_new)

    # Reference meme coins
    meme_coins = [
        "DezXAZ8z7PnrnRJjz3wXBoRgixCa6xjnB7YaB1pPB263",  # BONK
        "EKpQGSJtjMFqQ9caxuEyvokY8m84TxCGKmbu9M2mVLqL",  # WIF
        "7GCihgDB8fe6KNjn2MYtkzZcRjQy3t9GHdC8uHYmW2Hr",  # POPCAT
        "A8C3xuqvcDx1KuCPsQ7zQ1fZzqUHMCY3r3ofTF4LhStZ",  # MEW
        "ukHH6c7mMyiWCf1b9pqqVoBiCwSG5fqqDuKsCmfgrMc6",  # BOME
        "FNkm2sCa5Q7F8cHktur8k1YwvzvwP3V8JLJLfEhbEqG4"   # PNUT
    ]
    historical_norm = []
    duration = time_to - creation_new

    for addr in meme_coins:
        try:
            creation_h = get_creation_time(addr)
            time_to_h = creation_h + duration
            history_h = client.defi.history_price(
                address=addr,
                type_="1h",
                time_from=creation_h,
                time_to=time_to_h
            )
            items_h = history_h.get('data', {}).get('items', [])
            if len(items_h) < len_n:
                continue
            df_h = pd.DataFrame(items_h)
            df_h['time'] = pd.to_datetime(df_h['unixTime'], unit='s')
            df_h.set_index('time', inplace=True)
            price_h = df_h['value']
            normalized_h = price_h / price_h.iloc[0]
            sliced = normalized_h.iloc[0:len_n]
            historical_norm.append(sliced.values)
        except Exception as e:
            print(f"Error fetching data for {addr}: {e}")
            continue

    if not historical_norm:
        print("No historical data available from reference coins.")
        return

    # Create reflector waveform
    average_waveform = np.mean(historical_norm, axis=0)
    delta = 1
    psi_J = normalized_new.values
    psi_R = np.roll(average_waveform, delta)
    psi_R[:delta] = 0
    correlation = np.corrcoef(psi_J, psi_R)[0, 1] if len(psi_J) > 1 else 0

    # Collapse trigger theta
    pct = pd.Series(psi_J).pct_change().dropna()
    J = (pct > 0.1).sum()
    R = (pct < -0.1).sum()
    theta = np.heaviside(J / R - 1, 0) if R != 0 else (1 if J >= 1 else 0)

    # Memory strength weighting
    memory_strength = compute_memory_strength(pct)
    score = theta * correlation * np.log1p(memory_strength) if not np.isnan(correlation) else 0
    tag = classify_score(score)

    # Display
    print(f"\n🔺 Indicator Score: {score:.4f}")
    print(f"📡 Collapse Phase: {tag}")
    print(f"⏳ Temporal Echo Age: {len(psi_J)} ψ-units\n")


if __name__ == "__main__":
    api_key = input("Enter your Birdeye API key: ")
    new_address = input("Enter the new meme coin token address: ")
    main(api_key, new_address)
