CREATE TABLE [dbo].[BF_Service] (
    [Service_Id]      INT           IDENTITY (1, 1) NOT NULL,
    [ApplicationName] VARCHAR (100) NULL,
    [Is_Active]       BIT           CONSTRAINT [BF_Service_DF_IsActive] DEFAULT ((1)) NOT NULL,
    CONSTRAINT [BF_Service_PK_ServiceId] PRIMARY KEY CLUSTERED ([Service_Id] ASC)
);

