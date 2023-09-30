CREATE TABLE [dbo].[Service_ThreadPool_Data] (
    [Pool_Data_Id]    INT IDENTITY (1, 1) NOT NULL,
    [Grouping_Number] INT NOT NULL,
    [Pool_Id]         INT NOT NULL,
    CONSTRAINT [ThreadPoolData_FK_PoolId] FOREIGN KEY ([Pool_Id]) REFERENCES [dbo].[Service_ThreadPools] ([Pool_Id])
);

