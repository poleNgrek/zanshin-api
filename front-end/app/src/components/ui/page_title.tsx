import { Stack, Typography } from "@mui/material";

type PageTitleProps = {
  title: string;
  description?: string;
};

export function PageTitle({ title, description }: PageTitleProps) {
  return (
    <Stack spacing={1}>
      <Typography variant="h3" sx={{ fontWeight: 700, letterSpacing: -0.3 }}>
        {title}
      </Typography>
      {description ? (
        <Typography variant="body1" color="text.secondary" sx={{ maxWidth: 860 }}>
          {description}
        </Typography>
      ) : null}
    </Stack>
  );
}
