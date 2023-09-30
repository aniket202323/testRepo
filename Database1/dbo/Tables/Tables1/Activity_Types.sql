CREATE TABLE [dbo].[Activity_Types] (
    [Activity_Type_Id] INT           IDENTITY (1, 1) NOT NULL,
    [Activity_Desc]    VARCHAR (100) NULL,
    CONSTRAINT [Activity_PK_ActivityTypeId] PRIMARY KEY CLUSTERED ([Activity_Type_Id] ASC)
);

