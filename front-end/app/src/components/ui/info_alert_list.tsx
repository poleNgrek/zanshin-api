import { Alert, Stack } from "@mui/material";

type InfoAlertListItem = {
  id: string;
  text: string;
  severity?: "info" | "success" | "warning" | "error";
};

type InfoAlertListProps = {
  items: InfoAlertListItem[];
};

export function InfoAlertList({ items }: InfoAlertListProps) {
  return (
    <Stack spacing={1.25}>
      {items.map((item) => (
        <Alert key={item.id} severity={item.severity ?? "info"} variant="outlined">
          {item.text}
        </Alert>
      ))}
    </Stack>
  );
}
