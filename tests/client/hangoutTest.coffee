###
# Tests:
# * Going to /edit/PROJ_ID?isHangout=true&hangoutUrl=HANGOUT_URL&hangoutId=HANGOUT_ID
# sets those variables in session, and also in ProjectStatus
#
# ** If project has no hangoutUrl/hangoutId, set them
# ** If project has same hangoutUrl/hangoutId, don't do anything additional
# ** If a project has a different hangoutUrl or hangoutId, display warning alert message
#
# * If there are no ProjectStatuses with hangoutUrl/hangoutId for project,
# project.hangoutUrl and project.hangoutId are unset
#
# * Going to /registerHangout?isHangout=true&hangoutUrl=HANGOUT_URL&hangoutId=HANGOUT_ID
# sets those variables in session
#
# ** If there exists project with hangoutId==HANGOUT_ID, navigate from registerHangout to
# /edit/PROJ_ID?isHangout=true&hangoutUrl=HANGOUT_URL&hangoutId=HANGOUT_ID
###
