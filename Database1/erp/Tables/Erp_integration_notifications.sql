CREATE TABLE [erp].[Erp_integration_notifications] (
    [Id]            BIGINT             IDENTITY (1, 1) NOT NULL,
    [Message_Type]  VARCHAR (255)      NOT NULL,
    [Inserted_Date] DATETIMEOFFSET (7) NOT NULL,
    [Org]           VARCHAR (255)      NULL,
    [Key1]          VARCHAR (255)      NULL,
    [Key2]          VARCHAR (255)      NULL,
    [Key3]          VARCHAR (255)      NULL,
    [Key4]          VARCHAR (255)      NULL,
    [Key5]          VARCHAR (255)      NULL,
    CONSTRAINT [PK_Erp_integration_notifications] PRIMARY KEY CLUSTERED ([Id] ASC)
);

