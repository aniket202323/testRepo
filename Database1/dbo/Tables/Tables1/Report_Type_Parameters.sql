CREATE TABLE [dbo].[Report_Type_Parameters] (
    [RTP_Id]         INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Default_Value]  VARCHAR (7000) NULL,
    [Optional]       TINYINT        CONSTRAINT [DF_Report_Type_Parameters_Optional] DEFAULT ((0)) NOT NULL,
    [Report_Type_Id] INT            NOT NULL,
    [RP_Id]          INT            NULL,
    CONSTRAINT [ReportTypeParameters_PK_RTPId] PRIMARY KEY NONCLUSTERED ([RTP_Id] ASC),
    CONSTRAINT [FK_Report_Type_Parameters_Report_Parameters] FOREIGN KEY ([RP_Id]) REFERENCES [dbo].[Report_Parameters] ([RP_Id]),
    CONSTRAINT [ReportTypeParameters_FK_ReportTypeId] FOREIGN KEY ([Report_Type_Id]) REFERENCES [dbo].[Report_Types] ([Report_Type_Id])
);


GO
CREATE UNIQUE CLUSTERED INDEX [ReportTypeParameters_IXU_ReportTypeIdRTPId]
    ON [dbo].[Report_Type_Parameters]([Report_Type_Id] ASC, [RP_Id] ASC);

