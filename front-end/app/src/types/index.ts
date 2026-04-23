import type { z } from "zod";

import type {
    AnalyticsOverviewSchema,
    CompetitorSchema,
    DivisionSchema,
    GradingResultSchema,
    GradingSessionSchema,
    MatchSchema,
    TournamentSchema
} from "@zanshin/schemas";

export type AnalyticsOverview = z.infer<typeof AnalyticsOverviewSchema>;
export type Competitor = z.infer<typeof CompetitorSchema>;
export type Division = z.infer<typeof DivisionSchema>;
export type GradingResult = z.infer<typeof GradingResultSchema>;
export type GradingSession = z.infer<typeof GradingSessionSchema>;
export type Match = z.infer<typeof MatchSchema>;
export type Tournament = z.infer<typeof TournamentSchema>;
