import { Card, CardContent, Typography, type SxProps, type Theme } from "@mui/material";
import { type PropsWithChildren } from "react";

type SectionCardProps = PropsWithChildren<{
  title: string;
  titleVariant?: "h6" | "overline";
  sx?: SxProps<Theme>;
}>;

export function SectionCard({ title, titleVariant = "h6", sx, children }: SectionCardProps) {
  return (
    <Card sx={sx}>
      <CardContent>
        <Typography variant={titleVariant} sx={{ mb: 1 }}>
          {title}
        </Typography>
        {children}
      </CardContent>
    </Card>
  );
}
