CREATE TABLE [dbo].[GWay_Permanent_Clients] (
    [Is_Active] TINYINT      CONSTRAINT [GWay_Perm_Clients_DF_IsActive] DEFAULT ((1)) NULL,
    [Name]      VARCHAR (50) NOT NULL,
    CONSTRAINT [GWayPermClients_PK_Name] PRIMARY KEY NONCLUSTERED ([Name] ASC)
);

