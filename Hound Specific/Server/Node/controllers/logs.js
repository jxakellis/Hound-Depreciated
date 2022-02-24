const { queryPromise } = require('../utils/queryPromise')
const { formatDate, formatNumber, areAllDefined, atLeastOneDefined } = require('../utils/validateFormat')

/*
Known:
- userId formatted correctly and request has sufficient permissions to use
- dogId formatted correctly and request has sufficient permissions to use
- (if appliciable to controller) logId formatted correctly and request has sufficient permissions to use
*/


const getLogs = async (req, res) => {
    const dogId = formatNumber(req.params.dogId)
    const logId = formatNumber(req.params.logId)

    //if logId is defined and it is a number then continue
    if (logId) {
        try {
            const result = await queryPromise(req, 'SELECT * FROM dogLogs WHERE logId = ?', [logId])
            req.commitQueries(req)
            return res.status(200).json({ message: 'Success', result: result })
        } catch (error) {
            req.rollbackQueries(req)
            return res.status(400).json({ message: 'Invalid Parameters; Database query failed', error: error.message })
        }

    }
    else {
        try {
            const result = await queryPromise(req, 'SELECT * FROM dogLogs WHERE dogId = ?',
                [dogId])

            if (result.length === 0) {
                //successful but empty array, not logs to return
                req.commitQueries(req)
                return res.status(204).json({ message: 'Success', result: result })
            }
            else {
                //array has items, meaning there were logs found, successful!
                req.commitQueries(req)
                return res.status(200).json({ message: 'Success', result: result })
            }

        } catch (error) {
            //error when trying to do query to database
            req.rollbackQueries(req)
            return res.status(400).json({ message: 'Invalid Parameters; Database query failed', error: error.message })
        }
    }
}

const createLog = async (req, res) => {
    const dogId = formatNumber(req.params.dogId)
    const logDate = formatDate(req.body.date)
    const note = req.body.note
    const logType = req.body.logType
    const customTypeName = req.body.customTypeName

    if (areAllDefined([logDate, logType]) === false) {
        req.rollbackQueries(req)
        return res.status(400).json({ message: 'Invalid Body; date or logType missing' })
    }
    //see if logType is being updated to custom and tell the user to provide customTypeName if so.
    else if (logType === "Custom" && !customTypeName) {
        req.rollbackQueries(req)
        return res.status(400).json({ message: 'Invalid Body; No customTypeName Provided for "Custom" logType' })

    }

    try {
        const result = await queryPromise(req, 'INSERT INTO dogLogs(dogId, date, note, logType, customTypeName) VALUES (?, ?, ?, ?, ?)',
            [dogId, logDate, note, logType, customTypeName])
        req.commitQueries(req)
        return res.status(200).json({ message: 'Success', logId: result.insertId })
    } catch (error) {
        req.rollbackQueries(req)
        return res.status(400).json({ message: 'Invalid Parameters; Database query failed; Check date or logType format', error: error.message })
    }

}

const updateLog = async (req, res) => {

    const logId = formatNumber(req.params.logId)
    const logDate = formatDate(req.body.date)
    const note = req.body.note
    const logType = req.body.logType
    const customTypeName = req.body.customTypeName

    //if all undefined, then there is nothing to update
    if (atLeastOneDefined([logDate, note, logType]) === false) {
        req.rollbackQueries(req)
        return res.status(400).json({ message: 'Invalid Body; No date, note, or logType provided' })
    }
    //proper stuff is defined, then check to see customTypeName provided
    else if (logType === "Custom" && !customTypeName) {
        req.rollbackQueries(req)
        return res.status(400).json({ message: 'Invalid Body; No customTypeName provided for "Custom" logType' })

    }

    try {
        if (logDate) {
            await queryPromise(req, 'UPDATE dogLogs SET date = ? WHERE logId = ?', [logDate, logId])
        }
        if (note) {
            await queryPromise(req, 'UPDATE dogLogs SET note = ? WHERE logId = ?', [note, logId])
        }
        if (logType) {
            await queryPromise(req, 'UPDATE dogLogs SET logType = ? WHERE logId = ?', [logType, logId])
        }
        if (customTypeName) {
            await queryPromise(req, 'UPDATE dogLogs SET customTypeName = ? WHERE logId = ?', [customTypeName, logId])
        }
        req.commitQueries(req)
        return res.status(200).json({ message: 'Success' })
    } catch (error) {
        req.rollbackQueries(req)
        return res.status(400).json({ message: 'Invalid Body or Parameters; Database query failed; Check date or logType format', error: error.message })
    }
}


const delLog = require('../utils/delete').deleteLog
const deleteLog = async (req, res) => {
    const logId = formatNumber(req.params.logId)

    try {
        await delLog(req, logId)
        req.commitQueries(req)
        return res.status(200).json({ message: 'Success' })
    } catch (error) {
        req.rollbackQueries(req)
        return res.status(400).json({ message: 'Invalid Syntax; Database query failed', error: error.message })
    }
}

module.exports = { getLogs, createLog, updateLog, deleteLog }