import { Stack, Typography } from "@mui/material";

type PageTitleProps = {
  title: string;
  description?: string;
};

export function PageTitle({ title, description }: PageTitleProps) {
  return (
    <Stack spacing={0.5}>
      <Typography variant="h4">{title}</Typography>
      {description ? (
        <Typography variant="body1" color="text.secondary">
          {description}
        </Typography>
      ) : null}
    </Stack>
  );
}
