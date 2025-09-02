const express = require('express');
const { getUsers, createUser, updateUser, deleteUser, loginUser, signupUser } =
    require('../controllers/userController');

const router = express.Router();

router.route('/').get(getUsers).post(createUser);
router.route('/:id').put(updateUser).delete(deleteUser);
router.post('/login', loginUser); 
router.post("/register", signupUser);

module.exports = router;
