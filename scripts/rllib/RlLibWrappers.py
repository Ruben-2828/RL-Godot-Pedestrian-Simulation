# --- Observation normalization wrappers to ensure numpy arrays are returned ---
import numpy as np


def _extract_low_high(space):
    """Extract low/high bounds for the subspace keyed by 'obs' if present."""
    try:
        # gymnasium.spaces.Dict exposes .spaces (dict)
        if hasattr(space, "spaces") and isinstance(space.spaces, dict):
            sub = space.spaces.get("obs")
            if sub is not None and hasattr(sub, "low") and hasattr(sub, "high"):
                return sub.low, sub.high
        # Or the space itself is a Box
        if hasattr(space, "low") and hasattr(space, "high"):
            return space.low, space.high
    except Exception:
        pass
    return None, None


def _to_numpy_obs(obs, low=None, high=None):
    """
    Ensure observations match RLlib's expected structure: Dict('obs' -> np.ndarray).
    Converts any Python list at obs['obs'] to a numpy float32 array. Leaves other
    structures untouched.
    """
    if isinstance(obs, dict) and "obs" in obs:
        value = obs["obs"]
        if isinstance(value, list):
            obs = dict(obs)
            obs["obs"] = np.asarray(value, dtype=np.float32)
        elif isinstance(value, np.ndarray) and value.dtype != np.float32:
            obs = dict(obs)
            obs["obs"] = value.astype(np.float32, copy=False)
        # Clip to space if provided
        if low is not None and high is not None:
            obs = dict(obs)
            obs_arr = np.asarray(obs["obs"], dtype=np.float32)
            try:
                obs_arr = np.clip(obs_arr, low, high)
            except Exception:
                # Fallback to scalar clip if broadcasting fails
                obs_arr = np.clip(obs_arr, -1.0, 1.0)
            obs["obs"] = obs_arr
    return obs


class NumpyObsPZWrapper:
    """
    Minimal PettingZoo ParallelEnv-style wrapper that converts each agent's
    observation dict so that obs['obs'] is a numpy array.
    """

    def __init__(self, base_env):
        self.base_env = base_env

        # Expose observation/action spaces mapping if present
        self.observation_spaces = getattr(base_env, "observation_spaces", None)
        self.action_spaces = getattr(base_env, "action_spaces", None)

    def reset(self, *args, **kwargs):
        observations, info = self.base_env.reset(*args, **kwargs)
        observations = {
            aid: _to_numpy_obs(
                ob,
                *_extract_low_high(self.observation_spaces[
                                       aid]) if self.observation_spaces is not None and aid in self.observation_spaces else (
                None, None),
            )
            for aid, ob in observations.items()
        }
        return observations, info

    def step(self, actions):
        observations, rewards, terminations, truncations, infos = self.base_env.step(actions)
        observations = {
            aid: _to_numpy_obs(
                ob,
                *_extract_low_high(self.observation_spaces[
                                       aid]) if self.observation_spaces is not None and aid in self.observation_spaces else (
                None, None),
            )
            for aid, ob in observations.items()
        }
        return observations, rewards, terminations, truncations, infos

    def close(self):
        return self.base_env.close()

    def __getattr__(self, item):
        return getattr(self.base_env, item)