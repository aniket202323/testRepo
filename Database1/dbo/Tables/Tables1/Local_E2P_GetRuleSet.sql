CREATE TABLE [dbo].[Local_E2P_GetRuleSet] (
    [RuleId]    INT           IDENTITY (1, 1) NOT NULL,
    [Subsector] VARCHAR (50)  NOT NULL,
    [RuleSet]   VARCHAR (255) NOT NULL,
    [Rule]      VARCHAR (255) NOT NULL,
    CONSTRAINT [LocalE2PGetRuleSet_PK_RuleId] PRIMARY KEY CLUSTERED ([RuleId] ASC)
);

