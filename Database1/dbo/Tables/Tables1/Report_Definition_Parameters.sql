CREATE TABLE [dbo].[Report_Definition_Parameters] (
    [RDP_Id]    INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Report_Id] INT            NOT NULL,
    [RTP_Id]    INT            NOT NULL,
    [Value]     VARCHAR (7000) NULL,
    CONSTRAINT [ReportDefinitionParameter_PK_RDPId] PRIMARY KEY NONCLUSTERED ([RDP_Id] ASC),
    CONSTRAINT [ReportDefinitionParameters_FK_ReportId] FOREIGN KEY ([Report_Id]) REFERENCES [dbo].[Report_Definitions] ([Report_Id]),
    CONSTRAINT [ReportDefinitionParameters_FK_RTPId] FOREIGN KEY ([RTP_Id]) REFERENCES [dbo].[Report_Type_Parameters] ([RTP_Id])
);


GO
CREATE CLUSTERED INDEX [ReportDefinitionParameter_IX_ReportIdRTPId]
    ON [dbo].[Report_Definition_Parameters]([Report_Id] ASC, [RTP_Id] ASC);

