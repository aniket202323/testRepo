CREATE TABLE [dbo].[Local_PG_Object_Verification] (
    [ID]                   INT            IDENTITY (1, 1) NOT NULL,
    [DatabaseName]         VARCHAR (500)  NULL,
    [SQLObjectName]        VARCHAR (500)  NULL,
    [SQLType]              VARCHAR (100)  NULL,
    [SQLCreateDate]        DATETIME       NULL,
    [SQLModifiedDate]      DATETIME       NULL,
    [SQLWasUpdated]        BIT            NULL,
    [APPVersionObjectName] VARCHAR (500)  NULL,
    [APPVersionCreateDate] DATETIME       NULL,
    [APPVersionVersion]    VARCHAR (25)   NULL,
    [Status]               VARCHAR (5000) NULL,
    [CreatedDate]          DATETIME       NULL,
    CONSTRAINT [PK_Local_PG_Object_Verification] PRIMARY KEY CLUSTERED ([ID] ASC)
);

