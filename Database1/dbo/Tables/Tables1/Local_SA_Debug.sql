CREATE TABLE [dbo].[Local_SA_Debug] (
    [DebugId]        INT            IDENTITY (1, 1) NOT NULL,
    [DebugTimestamp] DATETIME       NOT NULL,
    [DebugSP]        VARCHAR (300)  NULL,
    [DebugInputs]    VARCHAR (300)  NULL,
    [DebugText]      VARCHAR (2000) NULL,
    CONSTRAINT [Local_SA_Debug_PK_DebugId] PRIMARY KEY NONCLUSTERED ([DebugId] ASC)
);

