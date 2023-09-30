CREATE TABLE [dbo].[User_Equipment_Assignment] (
    [ID]          BIGINT        IDENTITY (1, 1) NOT NULL,
    [EndTime]     DATETIME2 (7) NULL,
    [EquipmentId] INT           NOT NULL,
    [StartTime]   DATETIME2 (7) NOT NULL,
    [UserId]      INT           NOT NULL,
    CONSTRAINT [PK_User_Equipment_Assignment] PRIMARY KEY NONCLUSTERED ([ID] ASC),
    CONSTRAINT [FK_User_Equipment_Assignment_Equipment] FOREIGN KEY ([EquipmentId]) REFERENCES [dbo].[Prod_Units_Base] ([PU_Id]),
    CONSTRAINT [FK_User_Equipment_Assignment_Person] FOREIGN KEY ([UserId]) REFERENCES [dbo].[Users_Base] ([User_Id])
);


GO
CREATE CLUSTERED INDEX [UserEquipmentAssignment_Idx_EquipmentStartEnd]
    ON [dbo].[User_Equipment_Assignment]([EquipmentId] ASC, [StartTime] ASC, [EndTime] ASC);

