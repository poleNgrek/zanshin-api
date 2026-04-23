import { Card, CardContent, Typography, type SxProps, type Theme } from "@mui/material";
import { type PropsWithChildren } from "react";

type SectionCardProps = PropsWithChildren<{
  title: string;
  titleVariant?: "h6" | "overline";
  sx?: SxProps<Theme>;
}>;

export function SectionCard({ title, titleVariant = "h6", sx, children }: SectionCardProps) {
  return (
    <Card
      sx={{
        borderRadius: 2,
        border: "1px solid",
        borderColor: "divider",
        boxShadow: "0 8px 20px rgba(15, 23, 42, 0.05)",
        ...sx
      }}
    >
      <CardContent sx={{ p: { xs: 2, md: 2.5 } }}>
        <Typography variant={titleVariant} sx={{ mb: 1.25, fontWeight: 700 }}>
          {title}
        </Typography>
        {children}
      </CardContent>
    </Card>
  );
}
