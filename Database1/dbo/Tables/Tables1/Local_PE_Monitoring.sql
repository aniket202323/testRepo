CREATE TABLE [dbo].[Local_PE_Monitoring] (
    [Monitoring_Id] INT            IDENTITY (1, 1) NOT NULL,
    [Source_Name]   VARCHAR (250)  NOT NULL,
    [Path_Id]       INT            NULL,
    [Path_Code]     VARCHAR (50)   NULL,
    [Process_Order] VARCHAR (50)   NULL,
    [Material_Code] VARCHAR (50)   NULL,
    [TimeStamp]     DATETIME       NOT NULL,
    [Action]        VARCHAR (250)  NULL,
    [Comment]       NVARCHAR (MAX) NULL,
    [User_Id]       INT            NOT NULL,
    CONSTRAINT [PK_Local_PE_Monitoring] PRIMARY KEY CLUSTERED ([Monitoring_Id] ASC)
);

