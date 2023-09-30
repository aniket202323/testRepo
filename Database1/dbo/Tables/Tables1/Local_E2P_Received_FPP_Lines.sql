CREATE TABLE [dbo].[Local_E2P_Received_FPP_Lines] (
    [FPPLineId]   INT IDENTITY (1, 1) NOT NULL,
    [FPPId]       INT NOT NULL,
    [LineId]      INT NOT NULL,
    [ComponentId] INT NULL,
    CONSTRAINT [LocalE2PReceivedFPPLines_PK_FPPLineId] PRIMARY KEY CLUSTERED ([FPPLineId] ASC)
);

