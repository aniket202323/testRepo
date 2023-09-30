CREATE TABLE [dbo].[Report_Parameters] (
    [RP_Id]          INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Default_Value]  VARCHAR (7000) NULL,
    [Description]    VARCHAR (900)  NULL,
    [Is_Default]     SMALLINT       CONSTRAINT [DF_Report_Parameters_Is_Default] DEFAULT ((0)) NOT NULL,
    [MultiSelect]    TINYINT        NULL,
    [Portal_Mapping] VARCHAR (100)  NULL,
    [RP_Name]        VARCHAR (50)   NOT NULL,
    [RPG_Id]         INT            NULL,
    [RPT_Id]         INT            NOT NULL,
    [spName]         VARCHAR (50)   NULL,
    CONSTRAINT [PK___1__30] PRIMARY KEY CLUSTERED ([RP_Id] ASC),
    CONSTRAINT [FK_Report_Parameters_Report_Parameter_Groups] FOREIGN KEY ([RPG_Id]) REFERENCES [dbo].[Report_Parameter_Groups] ([Group_Id]),
    CONSTRAINT [FK_Report_Parameters_Report_Parameter_Types] FOREIGN KEY ([RPT_Id]) REFERENCES [dbo].[Report_Parameter_Types] ([RPT_Id]),
    CONSTRAINT [IX_Report_Parameters_1] UNIQUE NONCLUSTERED ([RP_Name] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IDX1_Report_Parameters]
    ON [dbo].[Report_Parameters]([Description] ASC);

