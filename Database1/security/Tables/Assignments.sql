﻿CREATE TABLE [security].[Assignments] (
    [id]            INT            IDENTITY (1, 1) NOT NULL,
    [name]          NVARCHAR (500) NOT NULL,
    [description]   NVARCHAR (255) NULL,
    [created_by]    NVARCHAR (255) NULL,
    [created_date]  DATETIME2 (7)  NULL,
    [modified_by]   NVARCHAR (255) NULL,
    [modified_date] DATETIME2 (7)  NULL,
    PRIMARY KEY CLUSTERED ([id] ASC)
);
