CREATE TABLE [dbo].[Dashboard_Icons] (
    [Dashboard_Icon_ID]   INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Dashboard_Icon]      IMAGE        NULL,
    [Dashboard_Icon_Name] VARCHAR (50) NULL,
    [Parent_Icon]         BIT          NULL,
    CONSTRAINT [PK_Dashboard_Icons] PRIMARY KEY CLUSTERED ([Dashboard_Icon_ID] ASC)
);

