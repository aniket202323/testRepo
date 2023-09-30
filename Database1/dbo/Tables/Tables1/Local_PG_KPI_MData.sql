CREATE TABLE [dbo].[Local_PG_KPI_MData] (
    [Id]                 INT            IDENTITY (1, 1) NOT NULL,
    [KPI]                VARCHAR (100)  NULL,
    [UnitOfMeasureLimit] VARCHAR (10)   NULL,
    [UpperLimit]         INT            NULL,
    [WhatToDo]           VARCHAR (7000) NULL
);

