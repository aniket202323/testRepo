CREATE TABLE [dbo].[Local_PG_KPIs] (
    [Id]          INT            IDENTITY (1, 1) NOT NULL,
    [KPI]         VARCHAR (100)  NULL,
    [DateCreated] DATETIME       NULL,
    [Equipment]   VARCHAR (255)  NULL,
    [OutCome]     VARCHAR (7000) NULL,
    [WhatToDo]    VARCHAR (7000) NULL,
    CONSTRAINT [PK_Local_PG_KPIs] PRIMARY KEY CLUSTERED ([Id] ASC)
);

