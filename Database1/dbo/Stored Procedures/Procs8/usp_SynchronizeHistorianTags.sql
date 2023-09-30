
CREATE PROCEDURE [dbo].[usp_SynchronizeHistorianTags]
	(
		@historianId As uniqueidentifier,
		@collectorId As uniqueidentifier = NULL,
		@sourceTags As [dbo].[TagTableType] Readonly
	)
AS
BEGIN
	DECLARE @Orphaned integer
	DECLARE @Updated integer
	DECLARE @Created integer

	SELECT @Orphaned = 0, @Updated = 0, @Created = 0

	-- update orphaned.....
	IF @collectorId IS NULL
		BEGIN
			UPDATE HT
			SET [Orphan] = 1
			FROM dbo.Historian_Tag HT
			WHERE
					HT.HistorianId	= @historianId
				AND HT.CollectorId	IS NULL
				AND NOT EXISTS (SELECT 1
								FROM @sourceTags SRC
								WHERE SRC.Name COLLATE DATABASE_DEFAULT = HT.Name COLLATE DATABASE_DEFAULT);
		END
	ELSE
		BEGIN
			UPDATE HT
			SET [Orphan] = 1
			FROM dbo.Historian_Tag HT
			WHERE
					HT.HistorianId	= @historianId
				AND HT.CollectorId	= @collectorId
				AND NOT EXISTS (SELECT 1
								FROM @sourceTags SRC
								WHERE SRC.Name COLLATE DATABASE_DEFAULT = HT.Name COLLATE DATABASE_DEFAULT);
		END
	SET @Orphaned = @@ROWCOUNT

	-- update where changes
	IF @collectorId IS NULL
		BEGIN
			UPDATE HT
			SET   [Description] = SRC.Description
				, [DataType]	= SRC.DataType
				, [Orphan]		= 0
				, [CollectorId] = NULL --@collectorId
				, [Version]		= IsNull(HT.Version, 0) + 1
			FROM dbo.Historian_Tag HT
				INNER JOIN @sourceTags SRC
					ON SRC.Name COLLATE DATABASE_DEFAULT = HT.Name COLLATE DATABASE_DEFAULT
			WHERE HT.HistorianId	= @historianId
				AND ( HASHBYTES('MD5',COALESCE(HT.Description, '' COLLATE DATABASE_DEFAULT)) <> HASHBYTES('MD5',COALESCE(SRC.Description, '' COLLATE DATABASE_DEFAULT))
					OR HT.DataType <> SRC.DataType
					OR HT.CollectorId IS NOT NULL
					OR HT.Orphan = 1 );
		END
	ELSE
		BEGIN
			UPDATE HT
			SET   [Description] = SRC.Description
				, [DataType]	= SRC.DataType
				, [Orphan]		= 0
				, [CollectorId] = @collectorId
				, [Version]		= IsNull(HT.Version, 0) + 1
			FROM dbo.Historian_Tag HT
				INNER JOIN @sourceTags SRC
					ON SRC.Name COLLATE DATABASE_DEFAULT = HT.Name COLLATE DATABASE_DEFAULT
			WHERE HT.HistorianId	= @historianId
				AND ( HASHBYTES('MD5',COALESCE(HT.Description, '' COLLATE DATABASE_DEFAULT)) <> HASHBYTES('MD5',COALESCE(SRC.Description, '' COLLATE DATABASE_DEFAULT))
					OR HT.DataType <> SRC.DataType
					OR HT.CollectorId IS NULL
					OR HT.CollectorId <> @collectorId
					OR HT.Orphan = 1 );
		END
		SET @Updated = @@ROWCOUNT

	-- insert new.....
		INSERT INTO dbo.Historian_Tag
			(Name, Description, DataType, Orphan, Id, Version, CollectorId, HistorianId) 
		SELECT SRC.Name, SRC.Description, SRC.DataType, 0, NEWID(), 1, @collectorId,  @historianId
		FROM  @sourceTags SRC
		WHERE NOT EXISTS (SELECT 1
						  FROM dbo.Historian_Tag HT
						  WHERE HT.HistorianId = @historianId
							AND HT.Name COLLATE DATABASE_DEFAULT = SRC.Name COLLATE DATABASE_DEFAULT);
		SET @Created = @@ROWCOUNT

	--SELECT Orphaned = @Orphaned, Updated = @Updated, Created = @Created
END