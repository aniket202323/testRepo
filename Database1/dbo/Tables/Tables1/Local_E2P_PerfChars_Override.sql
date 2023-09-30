CREATE TABLE [dbo].[Local_E2P_PerfChars_Override] (
    [PerfCharOverrideId] INT IDENTITY (1, 1) NOT NULL,
    [PerfCharId]         INT NOT NULL,
    [LineId]             INT NOT NULL,
    [UserId]             INT NOT NULL,
    [InitialPerfCharId]  INT NOT NULL,
    CONSTRAINT [LocalE2PPerfCharsOverride_PK_PerfCharOverrideId] PRIMARY KEY CLUSTERED ([PerfCharOverrideId] ASC),
    CONSTRAINT [FK_Local_E2P_PerfChars_Override_Local_E2P_PerfChars] FOREIGN KEY ([PerfCharId]) REFERENCES [dbo].[Local_E2P_PerfChars] ([PerfCharId]),
    CONSTRAINT [FK_Local_E2P_PerfChars_Override_Prod_Lines_Base] FOREIGN KEY ([LineId]) REFERENCES [dbo].[Prod_Lines_Base] ([PL_Id]),
    CONSTRAINT [FK_Local_E2P_PerfChars_Override_Users_Base] FOREIGN KEY ([UserId]) REFERENCES [dbo].[Users_Base] ([User_Id]),
    CONSTRAINT [UQ_Local_E2P_PerfChars_Override] UNIQUE NONCLUSTERED ([PerfCharId] ASC, [LineId] ASC, [UserId] ASC)
);

