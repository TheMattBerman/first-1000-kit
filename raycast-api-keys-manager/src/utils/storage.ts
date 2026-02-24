import { LocalStorage } from "@raycast/api";

export interface ApiKey {
  id: string;
  name: string;
  key: string;
  createdAt: number;
}

const STORAGE_KEY = "api-keys";

export async function getApiKeys(): Promise<ApiKey[]> {
  const data = await LocalStorage.getItem<string>(STORAGE_KEY);
  if (!data) {
    return [];
  }
  try {
    return JSON.parse(data) as ApiKey[];
  } catch (error) {
    console.error("Failed to parse API keys:", error);
    return [];
  }
}

export async function setApiKeys(keys: ApiKey[]): Promise<void> {
  await LocalStorage.setItem(STORAGE_KEY, JSON.stringify(keys));
}

export async function addApiKey(name: string, key: string): Promise<void> {
  const keys = await getApiKeys();
  const newKey: ApiKey = {
    id: Math.random().toString(36).substring(2, 9),
    name,
    key,
    createdAt: Date.now(),
  };
  keys.push(newKey);
  await setApiKeys(keys);
}

export async function deleteApiKey(id: string): Promise<void> {
  const keys = await getApiKeys();
  const newKeys = keys.filter((k) => k.id !== id);
  await setApiKeys(newKeys);
}

export async function updateApiKey(id: string, name: string, key: string): Promise<void> {
  const keys = await getApiKeys();
  const index = keys.findIndex((k) => k.id === id);
  if (index !== -1) {
    keys[index] = { ...keys[index], name, key };
    await setApiKeys(keys);
  }
}
