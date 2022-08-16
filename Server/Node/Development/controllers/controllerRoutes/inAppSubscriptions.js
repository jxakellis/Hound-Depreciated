const { getAllInAppSubscriptionsForFamilyId } = require('../getFor/getForInAppSubscriptions');
const { createInAppSubscriptionsForUserIdFamilyIdRecieptId } = require('../createFor/createForInAppSubscriptions');

async function getInAppSubscriptions(req, res) {
  try {
    const { familyId } = req.params;
    const result = await getAllInAppSubscriptionsForFamilyId(req.databaseConnection, familyId);
    return res.sendResponseForStatusJSONError(200, { result }, undefined);
  }
  catch (error) {
    return res.sendResponseForStatusJSONError(400, undefined, error);
  }
}

async function createInAppSubscriptions(req, res) {
  try {
    const { userId, familyId } = req.params;
    const { base64EncodedAppStoreReceiptURL } = req.body;
    const result = await createInAppSubscriptionsForUserIdFamilyIdRecieptId(req.databaseConnection, userId, familyId, base64EncodedAppStoreReceiptURL);
    return res.sendResponseForStatusJSONError(200, { result }, undefined);
  }
  catch (error) {
    return res.sendResponseForStatusJSONError(400, undefined, error);
  }
}

module.exports = {
  getInAppSubscriptions, createInAppSubscriptions,
};
