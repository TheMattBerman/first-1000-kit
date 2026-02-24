import { Form, ActionPanel, Action, useNavigation, showToast, Toast } from "@raycast/api";
import { useState } from "react";
import { addApiKey, updateApiKey, ApiKey } from "./utils/storage";

interface AddKeyFormProps {
  existingKey?: ApiKey;
  onKeyAdded: () => void;
}

export default function AddKeyForm({ existingKey, onKeyAdded }: AddKeyFormProps) {
  const [name, setName] = useState(existingKey?.name || "");
  const [key, setKey] = useState(existingKey?.key || "");
  const [nameError, setNameError] = useState<string | undefined>();
  const [keyError, setKeyError] = useState<string | undefined>();
  const { pop } = useNavigation();

  async function handleSubmit() {
    let hasError = false;
    if (!name) {
      setNameError("Name is required");
      hasError = true;
    }
    if (!key) {
      setKeyError("API Key is required");
      hasError = true;
    }

    if (hasError) return;

    try {
      if (existingKey) {
        await updateApiKey(existingKey.id, name, key);
        await showToast({ style: Toast.Style.Success, title: "API Key updated successfully!" });
      } else {
        await addApiKey(name, key);
        await showToast({ style: Toast.Style.Success, title: "API Key added successfully!" });
      }
      onKeyAdded();
      pop();
    } catch (error) {
      console.error(error);
      await showToast({ style: Toast.Style.Failure, title: "Failed to save API Key" });
    }
  }

  return (
    <Form
      actions={
        <ActionPanel>
          <Action.SubmitForm title={existingKey ? "Update API Key" : "Add API Key"} onSubmit={handleSubmit} />
        </ActionPanel>
      }
    >
      <Form.TextField
        id="name"
        title="Name"
        placeholder="e.g., OpenAI, Stripe, AWS..."
        value={name}
        onChange={(val) => {
          setName(val);
          if (val) setNameError(undefined);
        }}
        error={nameError}
      />
      <Form.PasswordField
        id="key"
        title="API Key"
        placeholder="sk-..."
        value={key}
        onChange={(val) => {
          setKey(val);
          if (val) setKeyError(undefined);
        }}
        error={keyError}
      />
    </Form>
  );
}
