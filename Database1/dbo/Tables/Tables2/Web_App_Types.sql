﻿CREATE TABLE [dbo].[Web_App_Types] (
    [WAT_Id]   INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [WAT_Desc] VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_Web_App_Types] PRIMARY KEY NONCLUSTERED ([WAT_Id] ASC)
);
