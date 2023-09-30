CREATE TABLE [dbo].[Report_ASPPrintQue] (
    [QId]         INT IDENTITY (1, 1) NOT NULL,
    [ReportId]    INT NOT NULL,
    [RunAttempts] INT NOT NULL,
    CONSTRAINT [ReportASPPrintQue_FK_ReportId] FOREIGN KEY ([ReportId]) REFERENCES [dbo].[Report_Definitions] ([Report_Id])
);

